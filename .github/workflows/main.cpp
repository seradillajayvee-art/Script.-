// =============================================================================
//  SA Mod Menu  -  GTA San Andreas Android (v2.00, armeabi-v7a) for AML
//  Tabs: WEAPONS | MODIFICATION   -   GTA V style touch UI, sounds, animations
//
//  NOTE: written without being able to compile/test on a real device.
//  Everything that touches the game is looked up by symbol name and logged to
//  Android/data/<package>/files/modmenu.log  -> send me that file if a feature
//  does not work and I will fix it.
// =============================================================================
#include <mod/amlmod.h>

#include <EGL/egl.h>
#include <GLES2/gl2.h>
#include <SLES/OpenSLES.h>
#include <SLES/OpenSLES_Android.h>
#include <android/log.h>
#include <elf.h>
#include <dlfcn.h>
#include <unistd.h>
#include <time.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <string>
#include <vector>
#include <mutex>

#include "imgui.h"
#include "imgui_impl_opengl3.h"

MYMOD(net.samodmenu.gtasa, SA Mod Menu, 1.0, ModMenu)

namespace mm {

// ----------------------------------------------------------------------------
//  CONFIG  (change here if the log tells you the layout is different)
// ----------------------------------------------------------------------------
#define ACC_R 240          // accent colour (orange)
#define ACC_G 160
#define ACC_B 30
#define OFF_FLAGS      0x18   // CWeaponInfo::m_nFlags
#define OFF_ANIMGROUP  0x1C   // CWeaponInfo::m_eAnimGroup
#define COPY_AIM_FLAGS 1      // also copy the "aim" flag bits of the reference weapon

// ----------------------------------------------------------------------------
//  DATA
// ----------------------------------------------------------------------------
struct WeaponDef { int id; const char* name; };
static const WeaponDef WEAPONS[] = {
    {1,"Brass Knuckles"},{2,"Golf Club"},{3,"Nightstick"},{4,"Knife"},{5,"Baseball Bat"},
    {6,"Shovel"},{7,"Pool Cue"},{8,"Katana"},{9,"Chainsaw"},{14,"Flowers"},{15,"Cane"},
    {16,"Grenade"},{17,"Tear Gas"},{18,"Molotov Cocktail"},
    {22,"Pistol"},{23,"Silenced Pistol"},{24,"Desert Eagle"},{25,"Shotgun"},{26,"Sawn-Off Shotgun"},
    {27,"Combat Shotgun"},{28,"Micro SMG"},{29,"MP5"},{30,"AK-47"},{31,"M4"},{32,"Tec-9"},
    {33,"Country Rifle"},{34,"Sniper Rifle"},{35,"RPG"},{36,"HS Rocket"},{37,"Flamethrower"},
    {38,"Minigun"},{39,"Satchel Charge"},{40,"Detonator"},{41,"Spray Can"},
    {42,"Fire Extinguisher"},{43,"Camera"},{46,"Parachute"}
};
#define WCOUNT ((int)(sizeof(WEAPONS)/sizeof(WEAPONS[0])))

static const int AMMO[] = {100, 250, 500, 1000, 5000, 9999};
#define AMMO_N ((int)(sizeof(AMMO)/sizeof(AMMO[0])))

// Shooting-animation styles. The style is copied from a "reference weapon"
// (its weapon.dat anim group). Swap the ids if you want a different look.
struct AnimStyle { const char* name; int ref; };
static const AnimStyle ANIMS[] = {
    {"Default",      0},
    {"Pistol Style", 22},   // Colt 45
    {"Two-Hand",     24},   // Desert Eagle
    {"One-Hand",     28},   // Micro SMG (one hand)
    {"SMG Style",    29},   // MP5
    {"Rifle Style",  30},   // AK-47
};
#define ANIM_N ((int)(sizeof(ANIMS)/sizeof(ANIMS[0])))

enum { M_TARGET, M_AMMOAMT, M_ADDAMMO, M_ALLW, M_CLEAR, M_STYLE, M_APPLYTO, M_APPLY, M_COUNT };
static const char* MOD_LABEL[M_COUNT] = {
    "Target Weapon", "Ammo Amount", "Add Ammo", "Weapon Cheat: All Weapons",
    "Remove All Weapons", "Shooting Animation", "Apply Animation To", "Apply Animation"
};

// ----------------------------------------------------------------------------
//  LOG / TOAST / TIME
// ----------------------------------------------------------------------------
static char g_logPath[256] = "/sdcard/modmenu.log";

static void mmLog(const char* fmt, ...) {
    char b[512]; va_list ap; va_start(ap, fmt); vsnprintf(b, sizeof b, fmt, ap); va_end(ap);
    __android_log_print(ANDROID_LOG_INFO, "SAModMenu", "%s", b);
    FILE* f = fopen(g_logPath, "a");
    if (f) { fputs(b, f); fputc('\n', f); fclose(f); }
}

static void InitLogPath() {
    char pkg[128] = {0};
    FILE* f = fopen("/proc/self/cmdline", "r");
    if (f) { size_t n = fread(pkg, 1, sizeof(pkg) - 1, f); (void)n; fclose(f); }
    if (pkg[0]) snprintf(g_logPath, sizeof g_logPath, "/storage/emulated/0/Android/data/%s/files/modmenu.log", pkg);
    FILE* t = fopen(g_logPath, "w");           // fresh log each launch
    if (t) fclose(t); else snprintf(g_logPath, sizeof g_logPath, "/sdcard/modmenu.log");
}

static double NowSec() { timespec ts; clock_gettime(CLOCK_MONOTONIC, &ts); return ts.tv_sec + ts.tv_nsec * 1e-9; }

static std::mutex g_toastMtx;
static char   g_toast[96] = "";
static double g_toastT = -100.0;
static void mmToast(const char* fmt, ...) {
    std::lock_guard<std::mutex> l(g_toastMtx);
    va_list ap; va_start(ap, fmt); vsnprintf(g_toast, sizeof g_toast, fmt, ap); va_end(ap);
    g_toastT = NowSec();
}

// ----------------------------------------------------------------------------
//  SYMBOL LOOKUP (reads libGTASA's .dynsym from disk so we can log / match names)
// ----------------------------------------------------------------------------
static void*                    hGTASA = nullptr;
static std::vector<std::string> g_syms;

static std::string FindLibPath(const char* lib) {
    FILE* f = fopen("/proc/self/maps", "r"); if (!f) return "";
    char line[1024]; std::string res;
    while (fgets(line, sizeof line, f)) {
        if (strstr(line, lib)) {
            char* p = strchr(line, '/');
            if (p) { res = p; while (!res.empty() && (res.back() == '\n' || res.back() == ' ')) res.pop_back(); break; }
        }
    }
    fclose(f); return res;
}

static void LoadSymbolTable(const char* lib) {
    std::string path = FindLibPath(lib);
    mmLog("%s path: %s", lib, path.c_str());
    if (path.empty()) return;
    FILE* f = fopen(path.c_str(), "rb"); if (!f) return;
    fseek(f, 0, SEEK_END); long sz = ftell(f); fseek(f, 0, SEEK_SET);
    if (sz < (long)sizeof(Elf32_Ehdr)) { fclose(f); return; }
    std::vector<uint8_t> buf(sz);
    if (fread(buf.data(), 1, sz, f) != (size_t)sz) { fclose(f); return; }
    fclose(f);
    Elf32_Ehdr* eh = (Elf32_Ehdr*)buf.data();
    if (memcmp(eh->e_ident, ELFMAG, SELFMAG) != 0 || eh->e_ident[EI_CLASS] != ELFCLASS32) { mmLog("not a 32-bit ELF file"); return; }
    if ((size_t)eh->e_shoff + (size_t)eh->e_shnum * sizeof(Elf32_Shdr) > (size_t)sz) return;
    Elf32_Shdr* sh = (Elf32_Shdr*)(buf.data() + eh->e_shoff);
    for (int i = 0; i < eh->e_shnum; ++i) {
        if (sh[i].sh_type != SHT_DYNSYM || sh[i].sh_link >= eh->e_shnum) continue;
        if ((size_t)sh[i].sh_offset + sh[i].sh_size > (size_t)sz) continue;
        Elf32_Shdr& st = sh[sh[i].sh_link];
        if ((size_t)st.sh_offset + st.sh_size > (size_t)sz) continue;
        Elf32_Sym* syms = (Elf32_Sym*)(buf.data() + sh[i].sh_offset);
        int n = sh[i].sh_size / sizeof(Elf32_Sym);
        const char* str = (const char*)(buf.data() + st.sh_offset);
        for (int j = 0; j < n; ++j)
            if (syms[j].st_name && syms[j].st_name < st.sh_size) g_syms.push_back(str + syms[j].st_name);
    }
    mmLog("exported symbols read: %d", (int)g_syms.size());
}

static void* SymFind(const char* key) {
    size_t kl = strlen(key);
    for (auto& s : g_syms)
        if (strncmp(s.c_str(), key, kl) == 0) {
            void* p = (void*)aml->GetSym(hGTASA, s.c_str());
            mmLog("  %-50s -> %s (%p)", key, s.c_str(), p);
            return p;
        }
    void* p = (void*)aml->GetSym(hGTASA, key);
    mmLog("  %-50s -> direct (%p)", key, p);
    return p;
}

// ----------------------------------------------------------------------------
//  GAME FUNCTIONS
// ----------------------------------------------------------------------------
typedef void* (*FindPlayerPed_t)(int);
typedef void  (*GiveWeapon_t)(void*, int, unsigned int, bool);
typedef void  (*GrantAmmo_t)(void*, int, unsigned int);
typedef void  (*SetCurWeapon_t)(void*, int);
typedef void  (*ClearWeapons_t)(void*);
typedef void* (*GetWeaponInfo_t)(int, signed char);

static FindPlayerPed_t pFindPlayerPed = nullptr;
static GiveWeapon_t    pGiveWeapon    = nullptr;
static GrantAmmo_t     pGrantAmmo     = nullptr;
static SetCurWeapon_t  pSetCurWeapon  = nullptr;
static ClearWeapons_t  pClearWeapons  = nullptr;
static GetWeaponInfo_t pGetWeaponInfo = nullptr;

static void ResolveGame() {
    mmLog("--- resolving game functions ---");
    pFindPlayerPed = (FindPlayerPed_t)SymFind("_Z13FindPlayerPed");
    pGiveWeapon    = (GiveWeapon_t)   SymFind("_ZN4CPed10GiveWeapon");
    pGrantAmmo     = (GrantAmmo_t)    SymFind("_ZN4CPed9GrantAmmo");
    pSetCurWeapon  = (SetCurWeapon_t) SymFind("_ZN4CPed16SetCurrentWeaponE11eWeaponType");
    pClearWeapons  = (ClearWeapons_t) SymFind("_ZN4CPed12ClearWeapons");
    pGetWeaponInfo = (GetWeaponInfo_t)SymFind("_ZN11CWeaponInfo13GetWeaponInfo");
}

// ----------------------------------------------------------------------------
//  ACTIONS  (queued from the UI, executed on the game thread)
// ----------------------------------------------------------------------------
enum { A_GIVE, A_AMMO, A_ALL, A_CLEAR, A_ANIM };
struct Action { int type, a, b; };
static std::mutex          g_actMtx;
static std::vector<Action> g_actions;
static bool                g_gameThreadHooked = false;

static void Post(int type, int a = 0, int b = 0) {
    std::lock_guard<std::mutex> l(g_actMtx);
    if (g_actions.size() < 64) g_actions.push_back(Action{type, a, b});
}

static void* Player() { return pFindPlayerPed ? pFindPlayerPed(-1) : nullptr; }
static const char* WName(int id) { for (auto& w : WEAPONS) if (w.id == id) return w.name; return "?"; }

static void DoGive(int id, int ammo) {
    if (!pGiveWeapon) { mmToast("GiveWeapon not found (see log)"); return; }
    void* p = Player(); if (!p) { mmToast("Player not ready"); return; }
    pGiveWeapon(p, id, (unsigned)ammo, true);
    if (pSetCurWeapon) pSetCurWeapon(p, id);
    mmToast("%s  x%d", WName(id), ammo);
}
static void DoAmmo(int id, int ammo) {
    if (!pGiveWeapon) { mmToast("GiveWeapon not found (see log)"); return; }
    void* p = Player(); if (!p) { mmToast("Player not ready"); return; }
    pGiveWeapon(p, id, 1, true);
    if (pGrantAmmo) pGrantAmmo(p, id, (unsigned)ammo); else pGiveWeapon(p, id, (unsigned)ammo, true);
    mmToast("+%d ammo: %s", ammo, WName(id));
}
static void DoAll(int ammo) {
    if (!pGiveWeapon) { mmToast("GiveWeapon not found (see log)"); return; }
    void* p = Player(); if (!p) { mmToast("Player not ready"); return; }
    for (auto& w : WEAPONS) pGiveWeapon(p, w.id, (unsigned)ammo, true);
    mmToast("All weapons  x%d", ammo);
}
static void DoClear() {
    if (!pClearWeapons) { mmToast("ClearWeapons not found (see log)"); return; }
    void* p = Player(); if (!p) { mmToast("Player not ready"); return; }
    pClearWeapons(p);
    mmToast("Weapons removed");
}

// --- animation style: rewrite the anim group inside CWeaponInfo (= weapon.dat in memory)
struct InfoBackup { uint8_t* info; int grp; uint32_t flg; };
static std::vector<InfoBackup> g_bak;
static InfoBackup* FindBak(uint8_t* i) { for (auto& b : g_bak) if (b.info == i) return &b; return nullptr; }

static bool ApplyAnim(int wid, int style) {
    if (!pGetWeaponInfo) return false;
    bool any = false;
    for (int sk = 0; sk < 3; ++sk) {                       // poor / std / pro skill entries
        uint8_t* info = (uint8_t*)pGetWeaponInfo(wid, (signed char)sk);
        if (!info) continue;
        int*      grp = (int*)(info + OFF_ANIMGROUP);
        uint32_t* flg = (uint32_t*)(info + OFF_FLAGS);
        if (*grp < 0 || *grp > 400) { mmLog("weapon %d skill %d: odd anim group %d -> layout mismatch, skipped", wid, sk, *grp); continue; }
        InfoBackup* b = FindBak(info);
        if (!b) { g_bak.push_back(InfoBackup{info, *grp, *flg}); b = &g_bak.back(); }
        if (style == 0) { *grp = b->grp; *flg = b->flg; any = true; continue; }
        uint8_t* ref = (uint8_t*)pGetWeaponInfo(ANIMS[style].ref, (signed char)sk);
        if (!ref) continue;
        InfoBackup* rb = FindBak(ref);
        int      rg = rb ? rb->grp : *(int*)(ref + OFF_ANIMGROUP);
        uint32_t rf = rb ? rb->flg : *(uint32_t*)(ref + OFF_FLAGS);
        *grp = rg;
#if COPY_AIM_FLAGS
        *flg = (*flg & ~0x3Fu) | (rf & 0x3Fu);
#else
        (void)rf;
#endif
        any = true;
    }
    return any;
}

static void DoAnim(int wid, int style) {
    if (!pGetWeaponInfo) { mmToast("GetWeaponInfo not found (see log)"); return; }
    bool ok = false;
    if (wid < 0) { for (int id = 22; id <= 34; ++id) ok |= ApplyAnim(id, style); }
    else {
        ok = ApplyAnim(wid, style);
        void* p = Player();
        if (ok && p && pSetCurWeapon) pSetCurWeapon(p, wid);     // re-equip so the new anim loads
    }
    if (ok) mmToast("%s: %s", wid < 0 ? "All Guns" : WName(wid), ANIMS[style].name);
    else    mmToast("Animation change failed (see log)");
}

static void DrainActions() {
    std::vector<Action> local;
    { std::lock_guard<std::mutex> l(g_actMtx); local.swap(g_actions); }
    for (auto& a : local) {
        switch (a.type) {
            case A_GIVE:  DoGive(a.a, a.b);  break;
            case A_AMMO:  DoAmmo(a.a, a.b);  break;
            case A_ALL:   DoAll(a.a);        break;
            case A_CLEAR: DoClear();         break;
            case A_ANIM:  DoAnim(a.a, a.b);  break;
        }
    }
}

// ----------------------------------------------------------------------------
//  UI SOUNDS (OpenSL ES, tiny generated blips)
// ----------------------------------------------------------------------------
enum { SFX_MOVE, SFX_SELECT, SFX_TAB, SFX_OPEN, SFX_CLOSE, SFX_N };
#define SFX_RATE 22050
#define SFX_MAX  (SFX_RATE / 8)
static int16_t g_sfx[SFX_N][SFX_MAX];
static int     g_sfxLen[SFX_N];
static SLObjectItf g_slEngineObj = nullptr, g_slMixObj = nullptr, g_slPlayerObj = nullptr;
static SLEngineItf g_slEngine = nullptr;
static SLPlayItf   g_slPlay = nullptr;
static SLAndroidSimpleBufferQueueItf g_slBq = nullptr;

static void MakeTone(int id, float f0, float f1, float ms, float vol) {
    int n = (int)(SFX_RATE * ms / 1000.f); if (n > SFX_MAX) n = SFX_MAX;
    float ph = 0.f;
    for (int i = 0; i < n; ++i) {
        float t = (float)i / (float)n;
        ph += 2.f * 3.14159265f * (f0 + (f1 - f0) * t) / SFX_RATE;
        float env = (1.f - t); env *= env;
        float atk = fminf(1.f, i / 80.f);
        g_sfx[id][i] = (int16_t)(sinf(ph) * env * atk * vol * 32767.f);
    }
    g_sfxLen[id] = n;
}

static void InitSound() {
    MakeTone(SFX_MOVE,   1100.f, 1100.f,  28.f, 0.30f);
    MakeTone(SFX_SELECT,  700.f, 1500.f,  75.f, 0.40f);
    MakeTone(SFX_TAB,     900.f, 1250.f,  50.f, 0.35f);
    MakeTone(SFX_OPEN,    420.f,  950.f, 115.f, 0.38f);
    MakeTone(SFX_CLOSE,   950.f,  420.f, 100.f, 0.35f);

    if (slCreateEngine(&g_slEngineObj, 0, nullptr, 0, nullptr, nullptr) != SL_RESULT_SUCCESS) { mmLog("OpenSL: engine failed"); return; }
    (*g_slEngineObj)->Realize(g_slEngineObj, SL_BOOLEAN_FALSE);
    (*g_slEngineObj)->GetInterface(g_slEngineObj, SL_IID_ENGINE, &g_slEngine);
    (*g_slEngine)->CreateOutputMix(g_slEngine, &g_slMixObj, 0, nullptr, nullptr);
    (*g_slMixObj)->Realize(g_slMixObj, SL_BOOLEAN_FALSE);

    SLDataLocator_AndroidSimpleBufferQueue locBq = {SL_DATALOCATOR_ANDROIDSIMPLEBUFFERQUEUE, 2};
    SLDataFormat_PCM fmt = {SL_DATAFORMAT_PCM, 1, SL_SAMPLINGRATE_22_05, SL_PCMSAMPLEFORMAT_FIXED_16,
                            SL_PCMSAMPLEFORMAT_FIXED_16, SL_SPEAKER_FRONT_CENTER, SL_BYTEORDER_LITTLEENDIAN};
    SLDataSource src = {&locBq, &fmt};
    SLDataLocator_OutputMix locOut = {SL_DATALOCATOR_OUTPUTMIX, g_slMixObj};
    SLDataSink snk = {&locOut, nullptr};
    const SLInterfaceID ids[1] = {SL_IID_ANDROIDSIMPLEBUFFERQUEUE};
    const SLboolean     req[1] = {SL_BOOLEAN_TRUE};
    if ((*g_slEngine)->CreateAudioPlayer(g_slEngine, &g_slPlayerObj, &src, &snk, 1, ids, req) != SL_RESULT_SUCCESS) { mmLog("OpenSL: player failed"); return; }
    (*g_slPlayerObj)->Realize(g_slPlayerObj, SL_BOOLEAN_FALSE);
    (*g_slPlayerObj)->GetInterface(g_slPlayerObj, SL_IID_PLAY, &g_slPlay);
    (*g_slPlayerObj)->GetInterface(g_slPlayerObj, SL_IID_ANDROIDSIMPLEBUFFERQUEUE, &g_slBq);
    if (g_slPlay) (*g_slPlay)->SetPlayState(g_slPlay, SL_PLAYSTATE_PLAYING);
    mmLog("UI sound ready");
}

static void PlaySfx(int id) {
    if (!g_slBq || id < 0 || id >= SFX_N) return;
    (*g_slBq)->Clear(g_slBq);
    (*g_slBq)->Enqueue(g_slBq, g_sfx[id], g_sfxLen[id] * 2);
}

// ----------------------------------------------------------------------------
//  UI STATE
// ----------------------------------------------------------------------------
struct Layout {
    float S = 1.f, W = 0, H = 0;
    float px = 0, py = 0, pw = 0;
    float hh = 0, th = 0, rowH = 0, listH = 0, fh = 0;
    float listY = 0, footY = 0, panelBottom = 0, selW = 0;
    float btnX = 0, btnY = 0, btnR = 0;
};
static Layout g_L;

static bool  g_open = false;
static float g_openT = 0.f;
static int   g_tab = 0;
static float g_tabX = 0.f, g_hiY = 0.f, g_flash = 0.f, g_nudgeL = 0.f, g_nudgeR = 0.f, g_btnPress = 0.f;
static int   g_sel[2] = {0, 0};
static float g_scroll[2] = {0, 0};
static float g_vel = 0.f;

static int   g_target = 0;       // index in WEAPONS
static int   g_ammoIdx = 2;
static int   g_styleIdx = 0;
static int   g_applyAll = 0;

static ImFont* g_fReg = nullptr;
static ImFont* g_fBold = nullptr;

static int RowCount(int tab) { return tab == 0 ? WCOUNT : (int)M_COUNT; }
static bool IsSelector(int tab, int r) { return tab == 1 && (r == M_TARGET || r == M_AMMOAMT || r == M_STYLE || r == M_APPLYTO); }
static int Wrap(int v, int n) { v %= n; if (v < 0) v += n; return v; }

static void ModValue(int r, char* out, size_t n) {
    switch (r) {
        case M_TARGET:  snprintf(out, n, "%s", WEAPONS[g_target].name); break;
        case M_AMMOAMT: snprintf(out, n, "%d", AMMO[g_ammoIdx]); break;
        case M_STYLE:   snprintf(out, n, "%s", ANIMS[g_styleIdx].name); break;
        case M_APPLYTO: snprintf(out, n, "%s", g_applyAll ? "All Guns" : "Target Weapon"); break;
        default: out[0] = 0;
    }
}

static void StepRow(int r, int dir) {
    switch (r) {
        case M_TARGET:  g_target = Wrap(g_target + dir, WCOUNT); break;
        case M_AMMOAMT: g_ammoIdx = Wrap(g_ammoIdx + dir, AMMO_N); break;
        case M_STYLE:   g_styleIdx = Wrap(g_styleIdx + dir, ANIM_N); break;
        case M_APPLYTO: g_applyAll ^= 1; break;
    }
}

static void ActRow(int tab, int r) {
    g_flash = 1.f; PlaySfx(SFX_SELECT);
    if (tab == 0) { g_target = r; Post(A_GIVE, WEAPONS[r].id, AMMO[g_ammoIdx]); return; }
    switch (r) {
        case M_ADDAMMO: Post(A_AMMO, WEAPONS[g_target].id, AMMO[g_ammoIdx]); break;
        case M_ALLW:    Post(A_ALL, AMMO[g_ammoIdx]); break;
        case M_CLEAR:   Post(A_CLEAR); break;
        case M_APPLY:   Post(A_ANIM, g_applyAll ? -1 : WEAPONS[g_target].id, g_styleIdx); break;
    }
}

static void ClampScroll() {
    float mx = fmaxf(0.f, RowCount(g_tab) * g_L.rowH - g_L.listH);
    if (g_scroll[g_tab] < 0.f) { g_scroll[g_tab] = 0.f; g_vel = 0.f; }
    if (g_scroll[g_tab] > mx)  { g_scroll[g_tab] = mx;  g_vel = 0.f; }
}

static void ComputeLayout(int w, int h) {
    Layout& L = g_L;
    L.W = (float)w; L.H = (float)h;
    L.S = fminf(2.5f, fmaxf(0.5f, h / 1080.f));
    float S = L.S, margin = 36.f * S;
    L.btnR = 32.f * S; L.btnX = margin + L.btnR; L.btnY = margin + L.btnR;
    L.px = margin; L.py = L.btnY + L.btnR + 14.f * S;
    L.pw = fminf(740.f * S, L.W * 0.55f);
    L.hh = 120.f * S; L.th = 64.f * S; L.rowH = 68.f * S; L.fh = 46.f * S;
    float avail = L.H - L.py - margin - L.hh - L.th - L.fh;
    int vis = (int)(avail / L.rowH); if (vis > 8) vis = 8; if (vis < 3) vis = 3;
    L.listH = vis * L.rowH;
    L.listY = L.py + L.hh + L.th;
    L.footY = L.listY + L.listH;
    L.panelBottom = L.footY + L.fh;
    L.selW = 360.f * S;
}

// ----------------------------------------------------------------------------
//  INPUT  (touch thread -> queue -> render thread)
// ----------------------------------------------------------------------------
struct TEv { int type; float x, y; };
static std::mutex g_evMtx;
static std::vector<TEv> g_evs;
static void QueueEv(int t, float x, float y) {
    std::lock_guard<std::mutex> l(g_evMtx);
    if (g_evs.size() < 256) g_evs.push_back(TEv{t, x, y});
}

enum { Z_NONE, Z_BTN, Z_TAB, Z_LIST, Z_PANEL };
static int    g_zone = Z_NONE;
static float  g_gy0 = 0.f, g_gy = 0.f;
static bool   g_drag = false;
static double g_lastMoveT = 0.0;

static int ZoneAt(float x, float y) {
    const Layout& L = g_L;
    float dx = x - L.btnX, dy = y - L.btnY, r = L.btnR * 1.4f;
    if (dx * dx + dy * dy <= r * r) return Z_BTN;
    if (!g_open || g_openT < 0.3f) return Z_NONE;
    if (x < L.px || x > L.px + L.pw || y < L.py || y > L.panelBottom) return Z_NONE;
    if (y >= L.py + L.hh && y < L.listY) return Z_TAB;
    if (y >= L.listY && y < L.footY)     return Z_LIST;
    return Z_PANEL;
}

static void SetOpen(bool o) { if (g_open != o) { g_open = o; PlaySfx(o ? SFX_OPEN : SFX_CLOSE); } }
static void SetTab(int t) { if (t != g_tab) { g_tab = t; g_hiY = (float)g_sel[t]; PlaySfx(SFX_TAB); } }

static void OnTap(float x, float y) {
    const Layout& L = g_L;
    int rows = RowCount(g_tab);
    int r = (int)floorf((y - L.listY + g_scroll[g_tab]) / L.rowH);
    if (r < 0 || r >= rows) return;
    if (g_sel[g_tab] != r) { g_sel[g_tab] = r; PlaySfx(SFX_MOVE); }
    if (IsSelector(g_tab, r)) {
        float rx = L.px + L.pw, sw = L.selW;
        if (x >= rx - sw && x < rx - sw * 0.45f)      { StepRow(r, -1); g_nudgeL = 1.f; PlaySfx(SFX_MOVE); }
        else if (x >= rx - sw * 0.45f)                { StepRow(r, +1); g_nudgeR = 1.f; PlaySfx(SFX_MOVE); }
    } else {
        ActRow(g_tab, r);
    }
}

static void PtrDown(float x, float y) {
    g_zone = ZoneAt(x, y); g_gy0 = g_gy = y; g_drag = false; g_vel = 0.f; g_lastMoveT = NowSec();
    if (g_zone == Z_BTN) g_btnPress = 1.f;
}
static void PtrMove(float x, float y) {
    (void)x;
    if (g_zone == Z_LIST) {
        float dy = y - g_gy;
        if (!g_drag && fabsf(y - g_gy0) > 16.f * g_L.S) g_drag = true;
        if (g_drag) {
            g_scroll[g_tab] -= dy; ClampScroll();
            double n = NowSec(), d = n - g_lastMoveT;
            if (d > 0.001) g_vel = g_vel * 0.5f + 0.5f * (-dy / (float)d);
            g_lastMoveT = n;
        }
    }
    g_gy = y;
}
static void PtrUp(float x, float y) {
    int z = g_zone; g_zone = Z_NONE;
    if (z == Z_BTN) { if (ZoneAt(x, y) == Z_BTN) SetOpen(!g_open); }
    else if (z == Z_TAB) { if (ZoneAt(x, y) == Z_TAB) SetTab(x < g_L.px + g_L.pw * 0.5f ? 0 : 1); }
    else if (z == Z_LIST) {
        if (!g_drag) OnTap(x, y);
        else if (NowSec() - g_lastMoveT > 0.08) g_vel = 0.f;
    }
}

static void ProcessEvents() {
    std::vector<TEv> ev;
    { std::lock_guard<std::mutex> l(g_evMtx); ev.swap(g_evs); }
    for (auto& e : ev) {
        if (e.type == 0) PtrDown(e.x, e.y);
        else if (e.type == 1) PtrMove(e.x, e.y);
        else PtrUp(e.x, e.y);
    }
}

// ----------------------------------------------------------------------------
//  DRAWING  (GTA V style)
// ----------------------------------------------------------------------------
static void TextAt(ImDrawList* dl, ImFont* f, float sz, float x, float y, ImU32 c, const char* s) {
    dl->AddText(f, sz, ImVec2(x, y), c, s);
}
static float TextW(ImFont* f, float sz, const char* s) { return f->CalcTextSizeA(sz, 100000.f, 0.f, s).x; }
static void Bar(ImDrawList* dl, float cx, float cy, float a, float hl, float th, ImU32 col) {
    dl->AddLine(ImVec2(cx - cosf(a) * hl, cy - sinf(a) * hl), ImVec2(cx + cosf(a) * hl, cy + sinf(a) * hl), col, th);
}
static ImU32 CA(int r, int g, int b, float a) {
    a = fminf(1.f, fmaxf(0.f, a));
    return IM_COL32(r, g, b, (int)(a * 255.f));
}

static void DrawUI(ImDrawList* dl, float dt) {
    Layout& L = g_L; const float S = L.S;

    // ---- animation state ----------------------------------------------------
    const float tgt = g_open ? 1.f : 0.f;
    g_openT += (tgt - g_openT) * fminf(1.f, dt * 14.f);
    if (fabsf(tgt - g_openT) < 0.004f) g_openT = tgt;
    g_tabX += ((float)g_tab - g_tabX) * fminf(1.f, dt * 16.f);
    g_hiY  += ((float)g_sel[g_tab] - g_hiY) * fminf(1.f, dt * 20.f);
    g_flash   = fmaxf(0.f, g_flash   - dt * 2.5f);
    g_nudgeL  = fmaxf(0.f, g_nudgeL  - dt * 7.f);
    g_nudgeR  = fmaxf(0.f, g_nudgeR  - dt * 7.f);
    g_btnPress = fmaxf(0.f, g_btnPress - dt * 6.f);
    if (!(g_zone == Z_LIST && g_drag)) {                       // inertia scrolling
        if (fabsf(g_vel) > 8.f) { g_scroll[g_tab] += g_vel * dt; g_vel *= expf(-4.f * dt); ClampScroll(); }
        else g_vel = 0.f;
    }
    auto C = [&](int r, int g, int b, float a) -> ImU32 { return CA(r, g, b, a * g_openT); };

    // ---- floating toggle button ----------------------------------------------
    {
        float cx = L.btnX, cy = L.btnY;
        float pulse = 1.f + 0.05f * sinf((float)ImGui::GetTime() * 3.f) * (1.f - g_openT);
        float r = L.btnR * pulse * (1.f - 0.12f * g_btnPress);
        dl->AddCircleFilled(ImVec2(cx, cy), r, CA(14, 14, 18, 0.82f), 48);
        dl->AddCircle(ImVec2(cx, cy), r, CA(ACC_R, ACC_G, ACC_B, 1.f), 48, 3.f * S);
        float t = g_openT, hl = 13.f * S, d = 9.f * S, th = 3.f * S;
        Bar(dl, cx, cy - d * (1.f - t),  0.785398f * t, hl, th, CA(255, 255, 255, 1.f));
        Bar(dl, cx, cy,                  0.f,           hl, th, CA(255, 255, 255, 1.f - t));
        Bar(dl, cx, cy + d * (1.f - t), -0.785398f * t, hl, th, CA(255, 255, 255, 1.f));
    }
    if (g_openT <= 0.001f) return;

    // ---- panel (slides in from the left + fades) -------------------------------
    const float ox = -(1.f - g_openT) * (L.pw + L.px + 30.f * S);
    const float x0 = L.px + ox, y0 = L.py, pw = L.pw;
    const float yH1 = y0 + L.hh, yT1 = L.listY, yL1 = L.footY, yF1 = L.panelBottom;
    const float fsz = 30.f * S;

    // header
    dl->AddRectFilledMultiColor(ImVec2(x0, y0), ImVec2(x0 + pw, yH1),
        C(14, 14, 18, 0.97f), C(150, 92, 10, 0.97f), C(150, 92, 10, 0.97f), C(14, 14, 18, 0.97f));
    dl->PushClipRect(ImVec2(x0, y0), ImVec2(x0 + pw, yH1), true);
    {
        float band = 90.f * S, slant = 40.f * S;
        float sx = x0 + fmodf((float)ImGui::GetTime() * 0.4f, 1.6f) * pw - 0.3f * pw;
        dl->AddQuadFilled(ImVec2(sx, yH1), ImVec2(sx + band, yH1), ImVec2(sx + band + slant, y0), ImVec2(sx + slant, y0),
                          C(255, 255, 255, 0.07f));
    }
    dl->PopClipRect();
    {
        const char* sub = "SAN ANDREAS";
        float ss = 22.f * S; float sw = TextW(g_fReg, ss, sub);
        TextAt(dl, g_fReg, ss, x0 + (pw - sw) * 0.5f, y0 + 12.f * S, C(ACC_R, ACC_G, ACC_B, 1.f), sub);
        const char* ttl = "MOD MENU";
        float ts = 62.f * S; float tw = TextW(g_fBold, ts, ttl);
        TextAt(dl, g_fBold, ts, x0 + (pw - tw) * 0.5f + 2.f * S, y0 + 40.f * S + 2.f * S, C(0, 0, 0, 0.6f), ttl);
        TextAt(dl, g_fBold, ts, x0 + (pw - tw) * 0.5f, y0 + 40.f * S, C(255, 255, 255, 1.f), ttl);
    }
    dl->AddRectFilled(ImVec2(x0, yH1 - 4.f * S), ImVec2(x0 + pw, yH1), C(ACC_R, ACC_G, ACC_B, 1.f));

    // tabs
    dl->AddRectFilled(ImVec2(x0, yH1), ImVec2(x0 + pw, yT1), C(0, 0, 0, 0.88f));
    {
        const char* names[2] = {"WEAPONS", "MODIFICATION"};
        float tsz = 26.f * S, tw2 = pw * 0.5f;
        for (int i = 0; i < 2; ++i) {
            float w = TextW(g_fBold, tsz, names[i]);
            float act = 1.f - fminf(1.f, fabsf(g_tabX - (float)i));
            int v = (int)(130.f + 125.f * act);
            TextAt(dl, g_fBold, tsz, x0 + tw2 * i + (tw2 - w) * 0.5f, yH1 + (L.th - tsz) * 0.5f - 2.f * S, C(v, v, v, 1.f), names[i]);
        }
        float ux = x0 + g_tabX * tw2 + 24.f * S;
        dl->AddRectFilled(ImVec2(ux, yT1 - 6.f * S), ImVec2(ux + tw2 - 48.f * S, yT1 - 1.f * S), C(ACC_R, ACC_G, ACC_B, 1.f));
    }

    // list
    const int   rows = RowCount(g_tab);
    const float maxScroll = fmaxf(0.f, rows * L.rowH - L.listH);
    dl->PushClipRect(ImVec2(x0, yT1), ImVec2(x0 + pw, yL1), true);
    for (int r = 0; r < rows; ++r) {
        float ry = yT1 + r * L.rowH - g_scroll[g_tab];
        if (ry + L.rowH < yT1 || ry > yL1) continue;
        dl->AddRectFilled(ImVec2(x0, ry), ImVec2(x0 + pw, ry + L.rowH), (r & 1) ? C(24, 24, 28, 0.84f) : C(10, 10, 12, 0.84f));
    }
    {   // animated highlight
        float hy = yT1 + g_hiY * L.rowH - g_scroll[g_tab];
        dl->AddRectFilled(ImVec2(x0, hy), ImVec2(x0 + pw, hy + L.rowH), C(250, 250, 250, 0.95f));
        dl->AddRectFilled(ImVec2(x0, hy), ImVec2(x0 + 6.f * S, hy + L.rowH), C(ACC_R, ACC_G, ACC_B, 1.f));
        if (g_flash > 0.f) dl->AddRectFilled(ImVec2(x0, hy), ImVec2(x0 + pw, hy + L.rowH), C(ACC_R, ACC_G, ACC_B, g_flash * 0.6f));
    }
    for (int r = 0; r < rows; ++r) {
        float ry = yT1 + r * L.rowH - g_scroll[g_tab];
        if (ry + L.rowH < yT1 || ry > yL1) continue;
        float ov = fmaxf(0.f, 1.f - fabsf((float)r - g_hiY));
        int v = (int)(255.f - 245.f * ov);
        ImU32 tc = C(v, v, v, 1.f);
        ImU32 ac = ov > 0.5f ? C(170, 95, 0, 1.f) : C(ACC_R, ACC_G, ACC_B, 1.f);
        float ty = ry + (L.rowH - fsz) * 0.5f, ay = ry + L.rowH * 0.5f, lx = x0 + 26.f * S;
        const char* label = g_tab == 0 ? WEAPONS[r].name : MOD_LABEL[r];
        if (g_tab == 0 && r == g_target) { dl->AddCircleFilled(ImVec2(lx, ay), 6.f * S, ac, 16); lx += 22.f * S; }
        TextAt(dl, g_fReg, fsz, lx, ty, tc, label);

        float rx = x0 + pw;
        if (IsSelector(g_tab, r)) {
            char vb[64]; ModValue(r, vb, sizeof vb);
            float armW = 58.f * S, vl = rx - L.selW + armW, vr = rx - armW;
            float vs = fsz * 0.95f;
            while (TextW(g_fReg, vs, vb) > (vr - vl) && vs > 14.f * S) vs -= 1.5f * S;
            float vw = TextW(g_fReg, vs, vb);
            TextAt(dl, g_fReg, vs, vl + ((vr - vl) - vw) * 0.5f, ry + (L.rowH - vs) * 0.5f, tc, vb);
            float s = 9.f * S;
            bool selRow = (r == g_sel[g_tab]);
            float lax = rx - L.selW + armW * 0.5f - (selRow ? g_nudgeL * 7.f * S : 0.f);
            float rax = rx - armW * 0.5f + (selRow ? g_nudgeR * 7.f * S : 0.f);
            dl->AddTriangleFilled(ImVec2(lax - s, ay), ImVec2(lax + s, ay - s * 1.2f), ImVec2(lax + s, ay + s * 1.2f), ac);
            dl->AddTriangleFilled(ImVec2(rax + s, ay), ImVec2(rax - s, ay - s * 1.2f), ImVec2(rax - s, ay + s * 1.2f), ac);
        } else {
            char rb[32];
            if (g_tab == 0)               snprintf(rb, sizeof rb, "GIVE  x%d", AMMO[g_ammoIdx]);
            else if (r == M_ADDAMMO)      snprintf(rb, sizeof rb, "+%d", AMMO[g_ammoIdx]);
            else                          snprintf(rb, sizeof rb, "RUN");
            float rs = fsz * 0.85f, rw = TextW(g_fBold, rs, rb);
            TextAt(dl, g_fBold, rs, rx - rw - 26.f * S, ry + (L.rowH - rs) * 0.5f, ac, rb);
        }
    }
    if (maxScroll > 0.f) {
        float bh = L.listH * L.listH / (rows * L.rowH);
        float by = yT1 + (L.listH - bh) * (g_scroll[g_tab] / maxScroll);
        dl->AddRectFilled(ImVec2(x0 + pw - 6.f * S, by), ImVec2(x0 + pw - 2.f * S, by + bh), C(ACC_R, ACC_G, ACC_B, 0.85f));
    }
    dl->PopClipRect();

    // footer: toast / hint  +  "3 / 12" counter
    dl->AddRectFilled(ImVec2(x0, yL1), ImVec2(x0 + pw, yF1), C(0, 0, 0, 0.90f));
    dl->AddRectFilled(ImVec2(x0, yF1 - 3.f * S), ImVec2(x0 + pw, yF1), C(ACC_R, ACC_G, ACC_B, 1.f));
    {
        char toast[96]; double tt;
        { std::lock_guard<std::mutex> l(g_toastMtx); memcpy(toast, g_toast, sizeof toast); tt = g_toastT; }
        float age = (float)(NowSec() - tt);
        float fs = 22.f * S, fy = yL1 + (L.fh - fs) * 0.5f - 1.f * S;
        if (age < 2.8f) {
            float a = age < 2.2f ? 1.f : 1.f - (age - 2.2f) / 0.6f;
            TextAt(dl, g_fBold, fs, x0 + 22.f * S, fy, C(ACC_R, ACC_G, ACC_B, a), toast);
        } else {
            TextAt(dl, g_fReg, fs, x0 + 22.f * S, fy, C(150, 150, 150, 1.f), "Tap = select   Drag = scroll   < > = change");
        }
        char cb[32]; snprintf(cb, sizeof cb, "%d / %d", g_sel[g_tab] + 1, rows);
        float cw = TextW(g_fReg, fs, cb);
        TextAt(dl, g_fReg, fs, x0 + pw - cw - 22.f * S, fy, C(220, 220, 220, 1.f), cb);
    }
}

// ----------------------------------------------------------------------------
//  IMGUI / EGL HOOK
// ----------------------------------------------------------------------------
static const char* kFontsRegular[] = {"/system/fonts/Roboto-Regular.ttf", "/system/fonts/RobotoCondensed-Regular.ttf", "/system/fonts/DroidSans.ttf", nullptr};
static const char* kFontsBold[]    = {"/system/fonts/Roboto-Bold.ttf", "/system/fonts/RobotoCondensed-Bold.ttf", "/system/fonts/DroidSans-Bold.ttf", nullptr};

static bool       g_imguiReady = false;
static bool       g_soundReady = false;
static EGLContext g_ctx = EGL_NO_CONTEXT;
static double     g_lastT = 0.0;
static bool       g_inFrame = false;

static ImFont* LoadFont(const char** list, float px) {
    ImGuiIO& io = ImGui::GetIO();
    ImFontConfig cfg; cfg.OversampleH = 1; cfg.OversampleV = 1;
    for (; *list; ++list)
        if (access(*list, R_OK) == 0) { ImFont* f = io.Fonts->AddFontFromFileTTF(*list, px, &cfg); if (f) return f; }
    return nullptr;
}

static void InitImGui(int w, int h) {
    ComputeLayout(w, h);
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO();
    io.IniFilename = nullptr; io.LogFilename = nullptr;
    float px = 40.f * g_L.S;
    g_fReg  = LoadFont(kFontsRegular, px);
    g_fBold = LoadFont(kFontsBold, px);
    if (!g_fReg)  g_fReg = io.Fonts->AddFontDefault();
    if (!g_fBold) g_fBold = g_fReg;
    ImGui_ImplOpenGL3_Init("#version 100");
    if (!g_soundReady) { InitSound(); g_soundReady = true; }
    g_imguiReady = true; g_lastT = NowSec();
    mmLog("ImGui ready (%dx%d, scale %.2f)", w, h, g_L.S);
}

static void RenderFrame(EGLContext ctx, int w, int h) {
    if (!g_imguiReady || ctx != g_ctx) {
        if (g_imguiReady) { ImGui::DestroyContext(); g_imguiReady = false; }   // EGL context was recreated
        InitImGui(w, h); g_ctx = ctx;
    }
    ImGuiIO& io = ImGui::GetIO();
    io.DisplaySize = ImVec2((float)w, (float)h);
    double now = NowSec(); float dt = (float)(now - g_lastT); g_lastT = now;
    if (dt <= 0.f || dt > 0.25f) dt = 1.f / 60.f;
    io.DeltaTime = dt;
    ComputeLayout(w, h);
    if (!g_gameThreadHooked) DrainActions();         // fallback when CTimer::Update couldn't be hooked
    ProcessEvents();
    ImGui_ImplOpenGL3_NewFrame();
    ImGui::NewFrame();
    DrawUI(ImGui::GetForegroundDrawList(), dt);
    ImGui::Render();
    ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
}

static EGLBoolean (*orig_eglSwapBuffers)(EGLDisplay, EGLSurface) = nullptr;
static EGLBoolean hk_eglSwapBuffers(EGLDisplay dpy, EGLSurface surf) {
    EGLContext ctx = eglGetCurrentContext();
    if (!g_inFrame && ctx != EGL_NO_CONTEXT && surf != EGL_NO_SURFACE) {
        EGLint w = 0, h = 0;
        eglQuerySurface(dpy, surf, EGL_WIDTH, &w); eglQuerySurface(dpy, surf, EGL_HEIGHT, &h);
        if (w > 0 && h > 0) { g_inFrame = true; RenderFrame(ctx, w, h); g_inFrame = false; }
    }
    return orig_eglSwapBuffers(dpy, surf);
}

// game thread tick
static void (*orig_CTimerUpdate)() = nullptr;
static void hk_CTimerUpdate() { orig_CTimerUpdate(); DrainActions(); }

// touch (NvEventQueueActivity.touchEvent: JNIEnv*, jobject, action, x, y, MotionEvent)
static int (*orig_touch)(void*, void*, int, int, int, void*) = nullptr;
static bool g_consuming = false;
static int hk_touch(void* env, void* thiz, int action, int x, int y, void* ev) {
    static int logged = 0;
    if (logged < 6) { mmLog("touch sample: action=%d x=%d y=%d", action, x, y); ++logged; }
    int a = action & 0xFF;
    if (a == 0) {                                   // DOWN
        g_consuming = (ZoneAt((float)x, (float)y) != Z_NONE);
        if (g_consuming) { QueueEv(0, (float)x, (float)y); return 1; }
    } else if (g_consuming && a == 2) {             // MOVE
        QueueEv(1, (float)x, (float)y); return 1;
    } else if (g_consuming && (a == 1 || a == 3)) { // UP / CANCEL
        QueueEv(2, (float)x, (float)y); g_consuming = false; return 1;
    }
    return orig_touch(env, thiz, action, x, y, ev);
}

static void* FindTouchSym() {
    void* p = SymFind("Java_com_nvidia_devtech_NvEventQueueActivity_touchEvent");
    if (p) return p;
    for (auto& s : g_syms)
        if (s.compare(0, 5, "Java_") == 0 && s.find("ouchEvent") != std::string::npos && s.find("ulti") == std::string::npos) {
            mmLog("  touch candidate: %s", s.c_str());
            return (void*)aml->GetSym(hGTASA, s.c_str());
        }
    return nullptr;
}

static void Start() {
    InitLogPath();
    mmLog("=== SA Mod Menu 1.0 loading ===");
    hGTASA = aml->GetLibHandle("libGTASA.so");
    if (!hGTASA) { mmLog("libGTASA.so handle is NULL - abort"); return; }

    for (int i = 0; i < WCOUNT; ++i) if (WEAPONS[i].id == 22) g_target = i;

    LoadSymbolTable("libGTASA.so");
    int shown = 0;
    for (auto& s : g_syms)
        if ((s.find("ouch") != std::string::npos || s.find("CTimer6Update") != std::string::npos) && shown < 80) { mmLog("  sym: %s", s.c_str()); ++shown; }
    ResolveGame();

    // render hook
    void* egl = dlopen("libEGL.so", RTLD_NOW);
    void* swap = egl ? dlsym(egl, "eglSwapBuffers") : nullptr;
    if (swap) { aml->Hook(swap, (void*)hk_eglSwapBuffers, (void**)&orig_eglSwapBuffers); mmLog("hooked eglSwapBuffers"); }
    else mmLog("!! eglSwapBuffers not found - no menu will be drawn");

    // game-thread hook
    void* tu = SymFind("_ZN6CTimer6Update");
    if (tu) { aml->Hook(tu, (void*)hk_CTimerUpdate, (void**)&orig_CTimerUpdate); g_gameThreadHooked = true; mmLog("hooked CTimer::Update"); }
    else mmLog("CTimer::Update not found - actions will run on the render thread");

    // touch hook
    void* tp = FindTouchSym();
    if (tp) { aml->Hook(tp, (void*)hk_touch, (void**)&orig_touch); mmLog("hooked touch"); }
    else mmLog("!! touch symbol not found - the menu cannot be tapped (send me this log)");

    mmLog("=== load finished ===");
}

} // namespace mm

extern "C" void OnModLoad() { mm::Start(); }
