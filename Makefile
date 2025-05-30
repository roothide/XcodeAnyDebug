export PACKAGE_VERSION := 1.0

ARCHS := arm64 arm64e
ifneq ($(THEOS_PACKAGE_SCHEME),)
TARGET := iphone:clang:16.5:15.0
else
TARGET := iphone:clang:14.5:14.0
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME += XcodeAnyDebug

XcodeAnyDebug_FILES += main.xm
XcodeAnyDebug_CFLAGS += -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
