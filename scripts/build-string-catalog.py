#!/usr/bin/env python3
"""Builds CCloudDesignSystem's Localizable.xcstrings from L10n.swift plus the Persian table below.

Every key in L10n.swift must have a Persian translation here, or the script fails, so the
two languages can't drift apart. Run after adding strings:

    python3 scripts/build-string-catalog.py
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(ROOT, "CCloud/CCloudKit/Sources/CCloudDesignSystem/Localization/L10n.swift")
CATALOG = os.path.join(ROOT, "CCloud/CCloudKit/Sources/CCloudDesignSystem/Resources/Localizable.xcstrings")

# Arguments of interpolated strings, in order: "d" for integers, "s" for strings.
ARGUMENTS = {
    "detail.seasonNumber": "d",
    "detail.episodeNumber": "d",
    "detail.episodeCode": "dd",
    "detail.playEpisode": "dd",
    "detail.playQuality": "s",
    "detail.qualityCount": "d",
    "detail.imdbRating": "s",
    "actions.appNotInstalledTitle": "s",
    "actions.appNotInstalledMessage": "s",
    "favorites.deletePlaylistMessage": "s",
    "favorites.emptyPlaylistMessage": "s",
    "favorites.titleCount": "d",
    "search.noResults": "s",
    "settings.watchedEpisodeCount": "d",
    "settings.seconds": "d",
    "about.version": "ss",
    "player.skipForward": "d",
    "player.skipBackward": "d",
    "player.track": "d",
    "error.server.message": "d",
}

# English singular forms for strings that vary with a count.
ENGLISH_ONE = {
    "detail.qualityCount": "%lld quality",
    "favorites.titleCount": "%lld title",
    "settings.watchedEpisodeCount": "%lld episode",
    "settings.seconds": "%lld second",
}

PERSIAN = {
    "tab.movies": "فیلم‌ها",
    "tab.series": "سریال‌ها",
    "tab.search": "جستجو",
    "tab.favorites": "علاقه‌مندی‌ها",
    "tab.settings": "تنظیمات",
    "tab.browse": "مرور",
    "tab.library": "کتابخانه",
    "common.retry": "تلاش دوباره",
    "common.cancel": "لغو",
    "common.done": "تمام",
    "common.save": "ذخیره",
    "common.delete": "حذف",
    "common.ok": "باشه",
    "common.create": "ایجاد",
    "common.rename": "تغییر نام",
    "common.refresh": "تازه‌سازی",
    "common.loading": "در حال بارگذاری…",
    "common.more": "بیشتر",
    "common.showMore": "نمایش بیشتر",
    "common.showLess": "نمایش کمتر",
    "common.untitled": "بدون عنوان",
    "kind.movie": "فیلم",
    "kind.series": "سریال",
    "catalog.allGenres": "همه‌ی ژانرها",
    "catalog.genre": "ژانر",
    "catalog.sortBy": "مرتب‌سازی",
    "catalog.filter": "فیلتر",
    "catalog.loadMoreFailed": "بارگذاری عنوان‌های بیشتر ممکن نشد.",
    "catalog.refreshFailed": "تازه‌سازی ممکن نشد. نتایج قبلی نمایش داده می‌شود.",
    "catalog.emptyTitle": "عنوانی نیست",
    "catalog.emptyMessage": "هنوز چیزی اینجا نیست. ژانر دیگری را امتحان کنید.",
    "catalog.countryEmptyMessage": "هنوز عنوانی از این کشور وجود ندارد.",
    "sort.recentlyAdded": "تازه‌ترین‌ها",
    "sort.releaseYear": "سال انتشار",
    "sort.imdbRating": "امتیاز IMDb",
    "detail.play": "پخش",
    "detail.favorite": "علاقه‌مندی",
    "detail.addToFavorites": "افزودن به علاقه‌مندی‌ها",
    "detail.removeFromFavorites": "حذف از علاقه‌مندی‌ها",
    "detail.addToPlaylist": "افزودن به پلی‌لیست…",
    "detail.qualities": "کیفیت‌ها",
    "detail.genres": "ژانرها",
    "detail.overview": "خلاصه",
    "detail.countries": "کشورها",
    "detail.seasons": "فصل‌ها",
    "detail.season": "فصل",
    "detail.episodes": "قسمت‌ها",
    "detail.watched": "دیده‌شده",
    "detail.markWatched": "علامت‌گذاری به‌عنوان دیده‌شده",
    "detail.markUnwatched": "علامت‌گذاری به‌عنوان دیده‌نشده",
    "detail.noSourcesTitle": "در دسترس نیست",
    "detail.noSourcesMessage": "هنوز فایلی برای پخش این عنوان وجود ندارد.",
    "detail.noSeasonsTitle": "قسمتی نیست",
    "detail.noSeasonsMessage": "هنوز قسمتی از این سریال منتشر نشده است.",
    "detail.seasonsFailed": "بارگذاری قسمت‌ها ممکن نشد.",
    "detail.imdb": "IMDb",
    "detail.chooseQuality": "انتخاب کیفیت",
    "detail.seasonNumber": "فصل %lld",
    "detail.episodeNumber": "قسمت %lld",
    "detail.episodeCode": "فصل %1$lld · قسمت %2$lld",
    "detail.playEpisode": "پخش فصل %1$lld · قسمت %2$lld",
    "detail.playQuality": "پخش %@",
    "detail.qualityCount": "%lld کیفیت",
    "detail.imdbRating": "امتیاز IMDb: %@",
    "actions.openIn": "باز کردن در",
    "actions.openInVLC": "باز کردن در VLC",
    "actions.openInInfuse": "باز کردن در Infuse",
    "actions.downloadInBrowser": "دانلود در مرورگر",
    "actions.copyLink": "کپی لینک",
    "actions.copyImageLink": "کپی لینک پوستر",
    "actions.share": "اشتراک‌گذاری",
    "actions.moreOptions": "گزینه‌های بیشتر",
    "actions.appNotInstalledTitle": "%@ نصب نیست",
    "actions.appNotInstalledMessage": "برای باز کردن ویدیو با %@، ابتدا آن را نصب کنید.",
    "favorites.all": "همه‌ی علاقه‌مندی‌ها",
    "favorites.playlists": "پلی‌لیست‌ها",
    "favorites.newPlaylist": "پلی‌لیست جدید",
    "favorites.newPlaylistEllipsis": "پلی‌لیست جدید…",
    "favorites.playlistName": "نام پلی‌لیست",
    "favorites.renamePlaylist": "تغییر نام پلی‌لیست",
    "favorites.renameEllipsis": "تغییر نام…",
    "favorites.deletePlaylist": "حذف پلی‌لیست",
    "favorites.deletePlaylistQuestion": "پلی‌لیست حذف شود؟",
    "favorites.editPlaylists": "پلی‌لیست‌ها…",
    "favorites.removeFromPlaylist": "حذف از پلی‌لیست",
    "favorites.removeAll": "حذف همه‌ی علاقه‌مندی‌ها",
    "favorites.removeAllQuestion": "همه‌ی علاقه‌مندی‌ها حذف شوند؟",
    "favorites.removeAllMessage": "همه‌ی علاقه‌مندی‌ها حذف و پلی‌لیست‌ها خالی می‌شوند. این کار برگشت‌پذیر نیست.",
    "favorites.removeAllConfirm": "حذف همه",
    "favorites.emptyTitle": "علاقه‌مندی‌ای نیست",
    "favorites.emptyMessage": "با زدن قلب در صفحه‌ی هر فیلم یا سریال، آن را اینجا ذخیره کنید.",
    "favorites.emptyPlaylistTitle": "پلی‌لیست خالی است",
    "favorites.noPlaylistsMessage": "برای دسته‌بندی علاقه‌مندی‌ها یک پلی‌لیست بسازید.",
    "favorites.choosePlaylists": "انتخاب پلی‌لیست‌ها",
    "favorites.deletePlaylistMessage": "«%@» حذف می‌شود. عنوان‌های آن در علاقه‌مندی‌ها باقی می‌مانند.",
    "favorites.emptyPlaylistMessage": "عنوان‌ها را از صفحه‌ی خودشان یا از «همه‌ی علاقه‌مندی‌ها» به «%@» اضافه کنید.",
    "favorites.titleCount": "%lld عنوان",
    "playlistError.emptyName": "یک نام برای پلی‌لیست وارد کنید.",
    "playlistError.duplicateName": "پلی‌لیستی با این نام وجود دارد.",
    "playlistError.notFound": "این پلی‌لیست دیگر وجود ندارد.",
    "search.prompt": "فیلم‌ها و سریال‌ها",
    "search.browseByCountry": "مرور بر اساس کشور",
    "search.startTitle": "جستجوی فیلم و سریال",
    "search.startMessage": "نام یک عنوان را بنویسید و جستجو کنید.",
    "search.countriesFailed": "بارگذاری کشورها ممکن نشد.",
    "search.results": "نتایج",
    "search.noResults": "نتیجه‌ای برای «%@» پیدا نشد.",
    "settings.appearance": "ظاهر",
    "settings.theme": "حالت نمایش",
    "settings.accentColor": "رنگ اصلی",
    "settings.font": "فونت",
    "settings.player": "پخش‌کننده",
    "settings.seekInterval": "فاصله‌ی پرش",
    "settings.seekIntervalFooter": "میزان جابه‌جایی دکمه‌های پرش و کلیدهای جهت‌نما در پخش‌کننده‌ی VLC.",
    "settings.subtitles": "زیرنویس",
    "settings.textColor": "رنگ متن",
    "settings.background": "پس‌زمینه",
    "settings.textSize": "اندازه‌ی متن",
    "settings.subtitlePreview": "زیرنویس‌ها این‌طور نمایش داده می‌شوند.",
    "settings.storage": "فضای ذخیره‌سازی",
    "settings.watchedEpisodes": "قسمت‌های دیده‌شده",
    "settings.clearWatched": "پاک کردن قسمت‌های دیده‌شده",
    "settings.clearWatchedQuestion": "قسمت‌های دیده‌شده پاک شوند؟",
    "settings.clearWatchedMessage": "همه‌ی علامت‌های «دیده‌شده» حذف می‌شوند. این کار برگشت‌پذیر نیست.",
    "settings.clear": "پاک کردن",
    "settings.reset": "بازگشت به تنظیمات پیش‌فرض",
    "settings.resetQuestion": "همه‌ی تنظیمات بازنشانی شوند؟",
    "settings.resetMessage": "تنظیمات ظاهر، پخش‌کننده و زیرنویس به حالت پیش‌فرض برمی‌گردند. علاقه‌مندی‌ها و قسمت‌های دیده‌شده حفظ می‌شوند.",
    "settings.resetConfirm": "بازنشانی",
    "settings.general": "عمومی",
    "settings.about": "درباره",
    "settings.language": "زبان",
    "settings.languageFooter": "CCloud از زبان دستگاه شما استفاده می‌کند. در تنظیمات سیستم می‌توانید زبان دیگری برای CCloud انتخاب کنید.",
    "settings.openSystemSettings": "باز کردن تنظیمات سیستم",
    "settings.watchedEpisodeCount": "%lld قسمت",
    "settings.seconds": "%lld ثانیه",
    "appearance.system": "سیستم",
    "appearance.light": "روشن",
    "appearance.dark": "تیره",
    "font.system": "فونت سیستم",
    "font.vazirmatn": "وزیرمتن",
    "color.default": "پیش‌فرض",
    "color.purple": "بنفش",
    "color.teal": "سبزآبی",
    "color.red": "قرمز",
    "color.pink": "صورتی",
    "color.purpleGrey": "بنفش خاکستری",
    "color.green": "سبز",
    "color.blue": "آبی",
    "color.yellow": "زرد",
    "color.white": "سفید",
    "color.black": "سیاه",
    "color.none": "بدون رنگ",
    "color.glass": "شیشه‌ای",
    "about.title": "درباره‌ی CCloud",
    "about.tagline": "فیلم و سریال روی آیفون، آیپد، مک و اپل‌تی‌وی.",
    "about.sourceCode": "کد منبع",
    "about.androidProject": "CCloud برای اندروید",
    "about.credits": "قدردانی",
    "about.androidCredit": "بر پایه‌ی اپ اندروید CCloud، ساخته‌ی حسین پیرا.",
    "about.fontCredit": "فونت وزیرمتن، اثر صابر راستی‌کردار (مجوز SIL Open Font).",
    "about.vlcCredit": "پخش فرمت‌های بیشتر با VLCKit از VideoLAN (مجوز LGPL).",
    "about.version": "نسخه‌ی %1$@ (%2$@)",
    "player.close": "بستن",
    "player.play": "پخش",
    "player.pause": "مکث",
    "player.speed": "سرعت پخش",
    "player.audio": "صدا",
    "player.subtitles": "زیرنویس",
    "player.off": "خاموش",
    "player.buffering": "در حال بارگذاری…",
    "player.failedTitle": "پخش این ویدیو ممکن نیست",
    "player.failedMessage": "ممکن است فایل در دسترس نباشد یا فرمت آن روی این دستگاه پشتیبانی نشود.",
    "player.fullScreen": "تمام‌صفحه",
    "player.position": "موقعیت پخش",
    "player.skipForward": "%lld ثانیه جلو",
    "player.skipBackward": "%lld ثانیه عقب",
    "player.track": "ترک %lld",
    "error.offline.title": "اتصال اینترنت برقرار نیست",
    "error.unreachable.title": "دسترسی به سرور ممکن نیست",
    "error.timedOut.title": "پاسخ سرور طول کشید",
    "error.server.title": "خطای سرور",
    "error.invalidResponse.title": "پاسخ نامعتبر",
    "error.unknown.title": "مشکلی پیش آمد",
    "error.offline.message": "اتصال اینترنت را بررسی کنید و دوباره تلاش کنید.",
    "error.unreachable.message": "دسترسی به سرورهای CCloud ممکن نشد. شاید در شبکه‌ی شما در دسترس نباشند.",
    "error.timedOut.message": "کمی بعد دوباره تلاش کنید.",
    "error.server.message": "سرور خطا برگرداند (%lld). بعداً دوباره تلاش کنید.",
    "error.invalidResponse.message": "سرور داده‌ای فرستاد که CCloud نتوانست بخواند.",
    "error.unknown.message": "لطفاً دوباره تلاش کنید.",
}

PATTERN = re.compile(r'String\(localized: "([^"]+)", defaultValue: "((?:[^"\\]|\\.)*)"')


def english_format(key, value):
    """Turns a Swift interpolation default value into a format string."""
    kinds = ARGUMENTS.get(key, "")
    parts = re.findall(r"\\\(", value)
    if len(parts) != len(kinds):
        sys.exit(f"{key}: {len(parts)} interpolations but {len(kinds)} argument types declared")
    positional = len(kinds) > 1
    for index, kind in enumerate(kinds, start=1):
        spec = "lld" if kind == "d" else "@"
        replacement = f"%{index}${spec}" if positional else f"%{spec}"
        value = re.sub(r"\\\([^)]*\)", replacement, value, count=1)
    return value.replace('\\"', '"')


def unit(value):
    return {"stringUnit": {"state": "translated", "value": value}}


def main():
    source = open(SOURCE, encoding="utf-8").read()
    entries = PATTERN.findall(source)
    keys = [key for key, _ in entries]
    duplicates = {key for key in keys if keys.count(key) > 1}
    if duplicates:
        sys.exit(f"Duplicate keys: {sorted(duplicates)}")
    missing = [key for key in keys if key not in PERSIAN]
    if missing:
        sys.exit(f"Missing Persian translations: {missing}")
    unused = sorted(set(PERSIAN) - set(keys))
    if unused:
        print(f"warning: translations for keys no longer in L10n.swift: {unused}")

    strings = {}
    for key, default in entries:
        english = english_format(key, default)
        persian = PERSIAN[key]
        for language, text in (("en", english), ("fa", persian)):
            if text.count("%") != english.count("%"):
                sys.exit(f"{key} ({language}): format specifiers don't match English: {text!r}")
        if key in ENGLISH_ONE:
            localizations = {
                "en": {"variations": {"plural": {"one": unit(ENGLISH_ONE[key]), "other": unit(english)}}},
                "fa": {"variations": {"plural": {"one": unit(persian), "other": unit(persian)}}},
            }
        else:
            localizations = {"en": unit(english), "fa": unit(persian)}
        strings[key] = {"extractionState": "manual", "localizations": localizations}

    catalog = {"sourceLanguage": "en", "strings": dict(sorted(strings.items())), "version": "1.0"}
    with open(CATALOG, "w", encoding="utf-8") as f:
        json.dump(catalog, f, ensure_ascii=False, indent=2, separators=(",", " : "))
        f.write("\n")
    print(f"Wrote {len(strings)} strings to {os.path.relpath(CATALOG, ROOT)}")


if __name__ == "__main__":
    main()
