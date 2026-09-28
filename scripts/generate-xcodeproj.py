#!/usr/bin/env python3
"""Writes CCloud/CCloud.xcodeproj: one app target and one shared scheme per platform.

The project is small on purpose. Sources live in file-system-synchronized folders
(App/Shared plus one folder per platform), and everything else comes from the local
Swift package CCloudKit. Re-run this after changing targets or build settings:

    python3 scripts/generate-xcodeproj.py
"""
import hashlib
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJECT_DIR = os.path.join(ROOT, "CCloud")
XCODEPROJ = os.path.join(PROJECT_DIR, "CCloud.xcodeproj")

TEAM = "987RHGW4P4"
BUNDLE_ID = "app.thepixelforge.CCloud"
MARKETING_VERSION = "1.0"
BUILD_NUMBER = "2"
PACKAGE_PRODUCT = "CCloudComposition"
PACKAGE_TESTS = ["CCloudDomainTests", "CCloudDataTests", "CCloudPresentationTests"]

COMMON_TARGET_SETTINGS = {
    "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": BUILD_NUMBER,
    "DEVELOPMENT_TEAM": TEAM,
    "ENABLE_PREVIEWS": "YES",
    "GENERATE_INFOPLIST_FILE": "YES",
    "INFOPLIST_KEY_CFBundleDisplayName": "CCloud TV",
    "INFOPLIST_KEY_LSApplicationCategoryType": "public.app-category.entertainment",
    "MARKETING_VERSION": MARKETING_VERSION,
    "PRODUCT_BUNDLE_IDENTIFIER": BUNDLE_ID,
    "PRODUCT_NAME": "CCloud",
    "STRING_CATALOG_GENERATE_SYMBOLS": "YES",
    "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
    "SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor",
    "SWIFT_EMIT_LOC_STRINGS": "YES",
    "SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY": "YES",
    "SWIFT_VERSION": "6.0",
}

TARGETS = [
    {
        "key": "ios",
        "name": "CCloud-iOS",
        "folder": "iOS",
        "strip_vlckit": True,
        "settings": {
            "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
            # The VLCKit thinning phase edits the embedded framework in place.
            "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
            "INFOPLIST_FILE": "Config/iOS/Info.plist",
            "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": "YES",
            "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
            "INFOPLIST_KEY_UILaunchScreen_Generation": "YES",
            "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad": "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight",
            "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone": "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight",
            "IPHONEOS_DEPLOYMENT_TARGET": "18.0",
            "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks"],
            "SDKROOT": "iphoneos",
            "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator",
            "SUPPORTS_MACCATALYST": "NO",
            "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "NO",
            "SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD": "NO",
            "TARGETED_DEVICE_FAMILY": "1,2",
        },
    },
    {
        "key": "tvos",
        "name": "CCloud-tvOS",
        "folder": "tvOS",
        "strip_vlckit": True,
        "settings": {
            "ASSETCATALOG_COMPILER_APPICON_NAME": "App Icon & Top Shelf Image",
            "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
            "INFOPLIST_FILE": "Config/tvOS/Info.plist",
            "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks"],
            "SDKROOT": "appletvos",
            "SUPPORTED_PLATFORMS": "appletvos appletvsimulator",
            "TARGETED_DEVICE_FAMILY": "3",
            "TVOS_DEPLOYMENT_TARGET": "18.0",
        },
    },
    {
        "key": "macos",
        "name": "CCloud-macOS",
        "folder": "macOS",
        "strip_vlckit": False,
        "settings": {
            "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
            # Sign to Run Locally for day-to-day builds; exports re-sign for distribution.
            "CODE_SIGN_IDENTITY[sdk=macosx*]": "-",
            "COMBINE_HIDPI_IMAGES": "YES",
            "ENABLE_APP_SANDBOX": "YES",
            "ENABLE_HARDENED_RUNTIME": "YES",
            "ENABLE_OUTGOING_NETWORK_CONNECTIONS": "YES",
            "ENABLE_USER_SELECTED_FILES": "readonly",
            "INFOPLIST_FILE": "Config/macOS/Info.plist",
            "INFOPLIST_KEY_NSHumanReadableCopyright": "",
            "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/../Frameworks"],
            "MACOSX_DEPLOYMENT_TARGET": "15.0",
            "SDKROOT": "macosx",
            "SUPPORTED_PLATFORMS": "macosx",
        },
    },
]

PROJECT_SETTINGS = {
    "ALWAYS_SEARCH_USER_PATHS": "NO",
    "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
    "CLANG_ANALYZER_NONNULL": "YES",
    "CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION": "YES_AGGRESSIVE",
    "CLANG_CXX_LANGUAGE_STANDARD": "gnu++20",
    "CLANG_ENABLE_MODULES": "YES",
    "CLANG_ENABLE_OBJC_ARC": "YES",
    "CLANG_ENABLE_OBJC_WEAK": "YES",
    "CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING": "YES",
    "CLANG_WARN_BOOL_CONVERSION": "YES",
    "CLANG_WARN_COMMA": "YES",
    "CLANG_WARN_CONSTANT_CONVERSION": "YES",
    "CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS": "YES",
    "CLANG_WARN_DIRECT_OBJC_ISA_USAGE": "YES_ERROR",
    "CLANG_WARN_DOCUMENTATION_COMMENTS": "YES",
    "CLANG_WARN_EMPTY_BODY": "YES",
    "CLANG_WARN_ENUM_CONVERSION": "YES",
    "CLANG_WARN_INFINITE_RECURSION": "YES",
    "CLANG_WARN_INT_CONVERSION": "YES",
    "CLANG_WARN_NON_LITERAL_NULL_CONVERSION": "YES",
    "CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF": "YES",
    "CLANG_WARN_OBJC_LITERAL_CONVERSION": "YES",
    "CLANG_WARN_OBJC_ROOT_CLASS": "YES_ERROR",
    "CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER": "YES",
    "CLANG_WARN_RANGE_LOOP_ANALYSIS": "YES",
    "CLANG_WARN_STRICT_PROTOTYPES": "YES",
    "CLANG_WARN_SUSPICIOUS_MOVE": "YES",
    "CLANG_WARN_UNGUARDED_AVAILABILITY": "YES_AGGRESSIVE",
    "CLANG_WARN_UNREACHABLE_CODE": "YES",
    "CLANG_WARN__DUPLICATE_METHOD_MATCH": "YES",
    "COPY_PHASE_STRIP": "NO",
    "DEVELOPMENT_TEAM": TEAM,
    "ENABLE_STRICT_OBJC_MSGSEND": "YES",
    "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    "GCC_C_LANGUAGE_STANDARD": "gnu17",
    "GCC_NO_COMMON_BLOCKS": "YES",
    "GCC_WARN_64_TO_32_BIT_CONVERSION": "YES",
    "GCC_WARN_ABOUT_RETURN_TYPE": "YES_ERROR",
    "GCC_WARN_UNDECLARED_SELECTOR": "YES",
    "GCC_WARN_UNINITIALIZED_AUTOS": "YES_AGGRESSIVE",
    "GCC_WARN_UNUSED_FUNCTION": "YES",
    "GCC_WARN_UNUSED_VARIABLE": "YES",
    "LOCALIZATION_PREFERS_STRING_CATALOGS": "YES",
    "MTL_FAST_MATH": "YES",
}
PROJECT_DEBUG = {
    "DEBUG_INFORMATION_FORMAT": "dwarf",
    "ENABLE_TESTABILITY": "YES",
    "GCC_DYNAMIC_NO_PIC": "NO",
    "GCC_OPTIMIZATION_LEVEL": "0",
    "GCC_PREPROCESSOR_DEFINITIONS": ["DEBUG=1", "$(inherited)"],
    "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
    "ONLY_ACTIVE_ARCH": "YES",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG $(inherited)",
    "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
}
PROJECT_RELEASE = {
    "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
    "ENABLE_NS_ASSERTIONS": "NO",
    "MTL_ENABLE_DEBUG_INFO": "NO",
    "SWIFT_COMPILATION_MODE": "wholemodule",
}

THIN_SCRIPT = '"${SRCROOT}/../scripts/thin-vlckit.sh"\n'


def oid(label):
    """A stable 24-hex-digit object id, so regenerating doesn't churn the file."""
    return hashlib.md5(("CCloud:" + label).encode()).hexdigest()[:24].upper()


def q(value):
    if re.fullmatch(r"[A-Za-z0-9_./]+", value):
        return value
    escaped = value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
    return f'"{escaped}"'


def settings_block(settings, indent):
    pad = "\t" * indent
    lines = []
    for key in sorted(settings):
        value = settings[key]
        if isinstance(value, list):
            items = "".join(f"{pad}\t{q(v)},\n" for v in value)
            lines.append(f"{pad}{q(key)} = (\n{items}{pad});\n")
        else:
            lines.append(f"{pad}{q(key)} = {q(value)};\n")
    return "".join(lines)


def main():
    ids = {
        "project": oid("project"),
        "main": oid("group.main"),
        "products": oid("group.products"),
        "app": oid("group.app"),
        "config": oid("group.config"),
        "shared": oid("sync.shared"),
        "package": oid("package.local"),
        "projectList": oid("configlist.project"),
        "projectDebug": oid("config.project.debug"),
        "projectRelease": oid("config.project.release"),
    }
    for t in TARGETS:
        k = t["key"]
        for part in ["target", "product", "sync", "sources", "frameworks", "resources", "script",
                     "dep", "buildfile", "list", "debug", "release", "configGroup", "plist"]:
            ids[f"{k}.{part}"] = oid(f"{k}.{part}")

    o = []
    o.append("// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {\n\t};\n\tobjectVersion = 77;\n\tobjects = {\n")

    o.append("\n/* Begin PBXBuildFile section */\n")
    for t in TARGETS:
        k = t["key"]
        o.append(f"\t\t{ids[k+'.buildfile']} /* {PACKAGE_PRODUCT} in Frameworks */ = {{isa = PBXBuildFile; productRef = {ids[k+'.dep']} /* {PACKAGE_PRODUCT} */; }};\n")
    o.append("/* End PBXBuildFile section */\n")

    o.append("\n/* Begin PBXFileReference section */\n")
    for t in TARGETS:
        k = t["key"]
        o.append(f"\t\t{ids[k+'.product']} /* CCloud.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = CCloud.app; sourceTree = BUILT_PRODUCTS_DIR; }};\n")
        o.append(f"\t\t{ids[k+'.plist']} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = \"<group>\"; }};\n")
    o.append("/* End PBXFileReference section */\n")

    o.append("\n/* Begin PBXFileSystemSynchronizedRootGroup section */\n")
    o.append(f"\t\t{ids['shared']} /* Shared */ = {{\n\t\t\tisa = PBXFileSystemSynchronizedRootGroup;\n\t\t\tpath = Shared;\n\t\t\tsourceTree = \"<group>\";\n\t\t}};\n")
    for t in TARGETS:
        k = t["key"]
        o.append(f"\t\t{ids[k+'.sync']} /* {t['folder']} */ = {{\n\t\t\tisa = PBXFileSystemSynchronizedRootGroup;\n\t\t\tpath = {t['folder']};\n\t\t\tsourceTree = \"<group>\";\n\t\t}};\n")
    o.append("/* End PBXFileSystemSynchronizedRootGroup section */\n")

    o.append("\n/* Begin PBXFrameworksBuildPhase section */\n")
    for t in TARGETS:
        k = t["key"]
        o.append(f"\t\t{ids[k+'.frameworks']} /* Frameworks */ = {{\n\t\t\tisa = PBXFrameworksBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t\t{ids[k+'.buildfile']} /* {PACKAGE_PRODUCT} in Frameworks */,\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};\n")
    o.append("/* End PBXFrameworksBuildPhase section */\n")

    o.append("\n/* Begin PBXGroup section */\n")
    o.append(f"\t\t{ids['main']} = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{ids['app']} /* App */,\n\t\t\t\t{ids['config']} /* Config */,\n\t\t\t\t{ids['products']} /* Products */,\n\t\t\t);\n\t\t\tsourceTree = \"<group>\";\n\t\t}};\n")
    app_children = f"\t\t\t\t{ids['shared']} /* Shared */,\n" + "".join(f"\t\t\t\t{ids[t['key']+'.sync']} /* {t['folder']} */,\n" for t in TARGETS)
    o.append(f"\t\t{ids['app']} /* App */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n{app_children}\t\t\t);\n\t\t\tpath = App;\n\t\t\tsourceTree = \"<group>\";\n\t\t}};\n")
    config_children = "".join(f"\t\t\t\t{ids[t['key']+'.configGroup']} /* {t['folder']} */,\n" for t in TARGETS)
    o.append(f"\t\t{ids['config']} /* Config */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n{config_children}\t\t\t);\n\t\t\tpath = Config;\n\t\t\tsourceTree = \"<group>\";\n\t\t}};\n")
    for t in TARGETS:
        k = t["key"]
        o.append(f"\t\t{ids[k+'.configGroup']} /* {t['folder']} */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{ids[k+'.plist']} /* Info.plist */,\n\t\t\t);\n\t\t\tpath = {t['folder']};\n\t\t\tsourceTree = \"<group>\";\n\t\t}};\n")
    products = "".join(f"\t\t\t\t{ids[t['key']+'.product']} /* CCloud.app */,\n" for t in TARGETS)
    o.append(f"\t\t{ids['products']} /* Products */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n{products}\t\t\t);\n\t\t\tname = Products;\n\t\t\tsourceTree = \"<group>\";\n\t\t}};\n")
    o.append("/* End PBXGroup section */\n")

    o.append("\n/* Begin PBXNativeTarget section */\n")
    for t in TARGETS:
        k = t["key"]
        phases = [f"{ids[k+'.sources']} /* Sources */", f"{ids[k+'.frameworks']} /* Frameworks */", f"{ids[k+'.resources']} /* Resources */"]
        if t["strip_vlckit"]:
            phases.append(f"{ids[k+'.script']} /* Thin VLCKit */")
        phase_lines = "".join(f"\t\t\t\t{p},\n" for p in phases)
        o.append(
            f"\t\t{ids[k+'.target']} /* {t['name']} */ = {{\n"
            f"\t\t\tisa = PBXNativeTarget;\n"
            f"\t\t\tbuildConfigurationList = {ids[k+'.list']} /* Build configuration list for PBXNativeTarget \"{t['name']}\" */;\n"
            f"\t\t\tbuildPhases = (\n{phase_lines}\t\t\t);\n"
            f"\t\t\tbuildRules = (\n\t\t\t);\n"
            f"\t\t\tdependencies = (\n\t\t\t);\n"
            f"\t\t\tfileSystemSynchronizedGroups = (\n\t\t\t\t{ids['shared']} /* Shared */,\n\t\t\t\t{ids[k+'.sync']} /* {t['folder']} */,\n\t\t\t);\n"
            f"\t\t\tname = {q(t['name'])};\n"
            f"\t\t\tpackageProductDependencies = (\n\t\t\t\t{ids[k+'.dep']} /* {PACKAGE_PRODUCT} */,\n\t\t\t);\n"
            f"\t\t\tproductName = CCloud;\n"
            f"\t\t\tproductReference = {ids[k+'.product']} /* CCloud.app */;\n"
            f"\t\t\tproductType = \"com.apple.product-type.application\";\n"
            f"\t\t}};\n"
        )
    o.append("/* End PBXNativeTarget section */\n")

    target_attributes = "".join(f"\t\t\t\t\t{ids[t['key']+'.target']} = {{\n\t\t\t\t\t\tCreatedOnToolsVersion = 27.0;\n\t\t\t\t\t}};\n" for t in TARGETS)
    target_list = "".join(f"\t\t\t\t{ids[t['key']+'.target']} /* {t['name']} */,\n" for t in TARGETS)
    o.append("\n/* Begin PBXProject section */\n")
    o.append(
        f"\t\t{ids['project']} /* Project object */ = {{\n"
        f"\t\t\tisa = PBXProject;\n"
        f"\t\t\tattributes = {{\n"
        f"\t\t\t\tBuildIndependentTargetsInParallel = 1;\n"
        f"\t\t\t\tLastSwiftUpdateCheck = 2700;\n"
        f"\t\t\t\tLastUpgradeCheck = 2700;\n"
        f"\t\t\t\tTargetAttributes = {{\n{target_attributes}\t\t\t\t}};\n"
        f"\t\t\t}};\n"
        f"\t\t\tbuildConfigurationList = {ids['projectList']} /* Build configuration list for PBXProject \"CCloud\" */;\n"
        f"\t\t\tdevelopmentRegion = en;\n"
        f"\t\t\thasScannedForEncodings = 0;\n"
        f"\t\t\tknownRegions = (\n\t\t\t\ten,\n\t\t\t\tfa,\n\t\t\t\tBase,\n\t\t\t);\n"
        f"\t\t\tmainGroup = {ids['main']};\n"
        f"\t\t\tminimizedProjectReferenceProxies = 1;\n"
        f"\t\t\tpackageReferences = (\n\t\t\t\t{ids['package']} /* XCLocalSwiftPackageReference \"CCloudKit\" */,\n\t\t\t);\n"
        f"\t\t\tpreferredProjectObjectVersion = 77;\n"
        f"\t\t\tproductRefGroup = {ids['products']} /* Products */;\n"
        f"\t\t\tprojectDirPath = \"\";\n"
        f"\t\t\tprojectRoot = \"\";\n"
        f"\t\t\ttargets = (\n{target_list}\t\t\t);\n"
        f"\t\t}};\n"
    )
    o.append("/* End PBXProject section */\n")

    o.append("\n/* Begin PBXResourcesBuildPhase section */\n")
    for t in TARGETS:
        k = t["key"]
        o.append(f"\t\t{ids[k+'.resources']} /* Resources */ = {{\n\t\t\tisa = PBXResourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};\n")
    o.append("/* End PBXResourcesBuildPhase section */\n")

    o.append("\n/* Begin PBXShellScriptBuildPhase section */\n")
    for t in TARGETS:
        if not t["strip_vlckit"]:
            continue
        k = t["key"]
        o.append(
            f"\t\t{ids[k+'.script']} /* Thin VLCKit */ = {{\n"
            f"\t\t\tisa = PBXShellScriptBuildPhase;\n"
            f"\t\t\talwaysOutOfDate = 1;\n"
            f"\t\t\tbuildActionMask = 2147483647;\n"
            f"\t\t\tfiles = (\n\t\t\t);\n"
            f"\t\t\tinputFileListPaths = (\n\t\t\t);\n"
            f"\t\t\tinputPaths = (\n\t\t\t);\n"
            f"\t\t\tname = \"Thin VLCKit\";\n"
            f"\t\t\toutputFileListPaths = (\n\t\t\t);\n"
            f"\t\t\toutputPaths = (\n\t\t\t);\n"
            f"\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
            f"\t\t\tshellPath = /bin/sh;\n"
            f"\t\t\tshellScript = {q(THIN_SCRIPT)};\n"
            f"\t\t\tshowEnvVarsInLog = 0;\n"
            f"\t\t}};\n"
        )
    o.append("/* End PBXShellScriptBuildPhase section */\n")

    o.append("\n/* Begin PBXSourcesBuildPhase section */\n")
    for t in TARGETS:
        k = t["key"]
        o.append(f"\t\t{ids[k+'.sources']} /* Sources */ = {{\n\t\t\tisa = PBXSourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};\n")
    o.append("/* End PBXSourcesBuildPhase section */\n")

    o.append("\n/* Begin XCBuildConfiguration section */\n")
    for name, extra, key in [("Debug", PROJECT_DEBUG, "projectDebug"), ("Release", PROJECT_RELEASE, "projectRelease")]:
        settings = {**PROJECT_SETTINGS, **extra}
        o.append(f"\t\t{ids[key]} /* {name} */ = {{\n\t\t\tisa = XCBuildConfiguration;\n\t\t\tbuildSettings = {{\n{settings_block(settings, 4)}\t\t\t}};\n\t\t\tname = {name};\n\t\t}};\n")
    for t in TARGETS:
        k = t["key"]
        settings = {**COMMON_TARGET_SETTINGS, **t["settings"]}
        for name, key in [("Debug", "debug"), ("Release", "release")]:
            o.append(f"\t\t{ids[k+'.'+key]} /* {name} */ = {{\n\t\t\tisa = XCBuildConfiguration;\n\t\t\tbuildSettings = {{\n{settings_block(settings, 4)}\t\t\t}};\n\t\t\tname = {name};\n\t\t}};\n")
    o.append("/* End XCBuildConfiguration section */\n")

    o.append("\n/* Begin XCConfigurationList section */\n")
    o.append(f"\t\t{ids['projectList']} /* Build configuration list for PBXProject \"CCloud\" */ = {{\n\t\t\tisa = XCConfigurationList;\n\t\t\tbuildConfigurations = (\n\t\t\t\t{ids['projectDebug']} /* Debug */,\n\t\t\t\t{ids['projectRelease']} /* Release */,\n\t\t\t);\n\t\t\tdefaultConfigurationIsVisible = 0;\n\t\t\tdefaultConfigurationName = Release;\n\t\t}};\n")
    for t in TARGETS:
        k = t["key"]
        o.append(f"\t\t{ids[k+'.list']} /* Build configuration list for PBXNativeTarget \"{t['name']}\" */ = {{\n\t\t\tisa = XCConfigurationList;\n\t\t\tbuildConfigurations = (\n\t\t\t\t{ids[k+'.debug']} /* Debug */,\n\t\t\t\t{ids[k+'.release']} /* Release */,\n\t\t\t);\n\t\t\tdefaultConfigurationIsVisible = 0;\n\t\t\tdefaultConfigurationName = Release;\n\t\t}};\n")
    o.append("/* End XCConfigurationList section */\n")

    o.append("\n/* Begin XCLocalSwiftPackageReference section */\n")
    o.append(f"\t\t{ids['package']} /* XCLocalSwiftPackageReference \"CCloudKit\" */ = {{\n\t\t\tisa = XCLocalSwiftPackageReference;\n\t\t\trelativePath = CCloudKit;\n\t\t}};\n")
    o.append("/* End XCLocalSwiftPackageReference section */\n")

    o.append("\n/* Begin XCSwiftPackageProductDependency section */\n")
    for t in TARGETS:
        k = t["key"]
        o.append(f"\t\t{ids[k+'.dep']} /* {PACKAGE_PRODUCT} */ = {{\n\t\t\tisa = XCSwiftPackageProductDependency;\n\t\t\tproductName = {PACKAGE_PRODUCT};\n\t\t}};\n")
    o.append("/* End XCSwiftPackageProductDependency section */\n")

    o.append(f"\t}};\n\trootObject = {ids['project']} /* Project object */;\n}}\n")

    os.makedirs(XCODEPROJ, exist_ok=True)
    with open(os.path.join(XCODEPROJ, "project.pbxproj"), "w") as f:
        f.write("".join(o))

    workspace = os.path.join(XCODEPROJ, "project.xcworkspace")
    os.makedirs(workspace, exist_ok=True)
    with open(os.path.join(workspace, "contents.xcworkspacedata"), "w") as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n<Workspace\n   version = "1.0">\n   <FileRef\n      location = "self:">\n   </FileRef>\n</Workspace>\n')

    schemes = os.path.join(XCODEPROJ, "xcshareddata", "xcschemes")
    os.makedirs(schemes, exist_ok=True)
    for t in TARGETS:
        with open(os.path.join(schemes, f"{t['name']}.xcscheme"), "w") as f:
            f.write(scheme(t, ids[t["key"] + ".target"]))
    print(f"Wrote {XCODEPROJ}")


def scheme(target, blueprint):
    app_ref = (
        '            <BuildableReference\n'
        '               BuildableIdentifier = "primary"\n'
        f'               BlueprintIdentifier = "{blueprint}"\n'
        '               BuildableName = "CCloud.app"\n'
        f'               BlueprintName = "{target["name"]}"\n'
        '               ReferencedContainer = "container:CCloud.xcodeproj">\n'
        '            </BuildableReference>\n'
    )
    testables = "".join(
        '         <TestableReference\n'
        '            skipped = "NO">\n'
        '            <BuildableReference\n'
        '               BuildableIdentifier = "primary"\n'
        f'               BlueprintIdentifier = "{name}"\n'
        f'               BuildableName = "{name}"\n'
        f'               BlueprintName = "{name}"\n'
        '               ReferencedContainer = "container:CCloudKit">\n'
        '            </BuildableReference>\n'
        '         </TestableReference>\n'
        for name in PACKAGE_TESTS
    )
    runnable = app_ref.replace("            <", "         <", 1).replace("\n            </BuildableReference>", "\n         </BuildableReference>")
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<Scheme\n   LastUpgradeVersion = "2700"\n   version = "1.7">\n'
        '   <BuildAction\n      parallelizeBuildables = "YES"\n      buildImplicitDependencies = "YES">\n'
        '      <BuildActionEntries>\n'
        '         <BuildActionEntry\n            buildForTesting = "YES"\n            buildForRunning = "YES"\n            buildForProfiling = "YES"\n            buildForArchiving = "YES"\n            buildForAnalyzing = "YES">\n'
        f'{app_ref}'
        '         </BuildActionEntry>\n'
        '      </BuildActionEntries>\n'
        '   </BuildAction>\n'
        '   <TestAction\n      buildConfiguration = "Debug"\n      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"\n      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"\n      shouldUseLaunchSchemeArgsEnv = "YES">\n'
        '      <Testables>\n'
        f'{testables}'
        '      </Testables>\n'
        '   </TestAction>\n'
        '   <LaunchAction\n      buildConfiguration = "Debug"\n      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"\n      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"\n      launchStyle = "0"\n      useCustomWorkingDirectory = "NO"\n      ignoresPersistentStateOnLaunch = "NO"\n      debugDocumentVersioning = "YES"\n      debugServiceExtension = "internal"\n      allowLocationSimulation = "YES">\n'
        '      <BuildableProductRunnable\n         runnableDebuggingMode = "0">\n'
        f'{runnable}'
        '      </BuildableProductRunnable>\n'
        '      <CommandLineArguments>\n'
        '         <CommandLineArgument\n            argument = "-demo"\n            isEnabled = "NO">\n         </CommandLineArgument>\n'
        '      </CommandLineArguments>\n'
        '   </LaunchAction>\n'
        '   <ProfileAction\n      buildConfiguration = "Release"\n      shouldUseLaunchSchemeArgsEnv = "YES"\n      savedToolIdentifier = ""\n      useCustomWorkingDirectory = "NO"\n      debugDocumentVersioning = "YES">\n'
        '      <BuildableProductRunnable\n         runnableDebuggingMode = "0">\n'
        f'{runnable}'
        '      </BuildableProductRunnable>\n'
        '   </ProfileAction>\n'
        '   <AnalyzeAction\n      buildConfiguration = "Debug">\n   </AnalyzeAction>\n'
        '   <ArchiveAction\n      buildConfiguration = "Release"\n      revealArchiveInOrganizer = "YES">\n   </ArchiveAction>\n'
        '</Scheme>\n'
    )


if __name__ == "__main__":
    main()
