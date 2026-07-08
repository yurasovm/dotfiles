# dotfiles

Модульное окружение (zsh, nvim, claude, herdr…). Конфиги — источник правды,
раскатываются симлинками (stow) на macOS и Linux. Ставятся **только выбранные**
модули; остальные конфиги просто лежат в репозитории неактивными.

## Установка

```bash
git clone git@github.com:yurasovm/dotfiles ~/dotfiles && cd ~/dotfiles
./install                     # интерактивный выбор модулей
./install zsh nvim            # только эти (+ зависимости)
./install --profile server    # набор из profiles/server
```

Прочие команды:
```bash
./install --list      # каталог модулей: name  platforms  описание
./install --select    # только выбрать (печатает список, ничего не ставит)
```

## Как устроен модуль

```
modules/<имя>/
├── module.conf     # desc, platforms (mac/linux), deps, default (on/off)
├── packages.apt    # пакеты для Linux (по строке)
├── packages.brew   # пакеты для macOS
├── setup.sh        # шаги, не сводящиеся к пакету (бинарники, плагины)
└── config/         # stow-пакет: раскладка как в $HOME (config/.zshrc → ~/.zshrc)
```

Метаданные лежат рядом с `config/`, поэтому stow видит только `config/`
(линкует `stow -d modules/<имя> -t $HOME config`). Модуль может быть только-конфиг,
только-установщик или и то и другое.

## Профили

`profiles/<имя>` — список модулей (по строке). `desktop` — для мака,
`server` — для сервера. Используются как `--profile <имя>` и как предвыбор в меню.

## macOS vs Linux

Различия — ветками `$OSTYPE` внутри конфигов и `packages.apt` / `packages.brew`.
Машинно-специфичное и секреты — в `~/.zshrc.local` (не в гите).
