export PACKAGE_VERSION := 1.0

ARCHS := arm64 arm64e
ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
JBROOT := 
ROOTFS := /rootfs
TARGET := iphone:clang:16.5:15.0
else ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
JBROOT := /var/jb
ROOTFS := 
TARGET := iphone:clang:16.5:15.0
else
JBROOT := 
ROOTFS := 
TARGET := iphone:clang:14.5:14.0
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME += XcodeAnyDebug

XcodeAnyDebug_FILES += main.x
XcodeAnyDebug_CFLAGS += -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

before-package::
	for file in \
		$(THEOS_STAGING_DIR)/DEBIAN/* \
		$(THEOS_STAGING_DIR)/usr/libexec/XcodeAnyDebug-startup \
		$(THEOS_STAGING_DIR)/Library/LaunchDaemons/XcodeAnyDebug-startup.plist \
	; do \
		sed -e "s|@JBROOT@|$(JBROOT)|g" -e "s|@ROOTFS@|$(ROOTFS)|g" "$$file" > "$$file.tmp"; \
		cat "$$file.tmp" > "$$file"; \
		rm -f "$$file.tmp"; \
	done
