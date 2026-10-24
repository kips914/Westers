# Сборка Warhead в GitHub Actions

Minecraft 1.20.1, Forge 47.2.0, Java 17, Gradle 8.8 (ставится в раннере, wrapper не нужен).

1. Создай репозиторий, загрузи в корень СОДЕРЖИМОЕ папки Warhead (вместе с `.github/workflows/build.yml`).
2. Actions -> "Build Warhead JAR" -> Run workflow (или просто коммит в main/master).
3. В запуске, внизу, в Artifacts скачай `warhead-<версия>` — внутри jar для папки mods.
4. Ошибка компиляции: открой шаг "Build", найди первую строку `error:`. Артефакт `build-reports` тоже прикрепляется.
5. Релиз: создай тег `v1.2.1` — jar сам появится в разделе Releases.
