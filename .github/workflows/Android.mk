LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE    := ModMenu
LOCAL_SRC_FILES := main.cpp \
                   imgui/imgui.cpp \
                   imgui/imgui_draw.cpp \
                   imgui/imgui_tables.cpp \
                   imgui/imgui_widgets.cpp \
                   imgui/backends/imgui_impl_opengl3.cpp

LOCAL_C_INCLUDES := $(LOCAL_PATH) \
                    $(LOCAL_PATH)/AML \
                    $(LOCAL_PATH)/AML/include \
                    $(LOCAL_PATH)/imgui \
                    $(LOCAL_PATH)/imgui/backends

LOCAL_CFLAGS    := -O2 -DNDEBUG -DAML32 -DIMGUI_IMPL_OPENGL_ES2 -w
LOCAL_CPPFLAGS  := -std=c++17
LOCAL_LDLIBS    := -llog -lEGL -lGLESv2 -lOpenSLES -ldl

include $(BUILD_SHARED_LIBRARY)
