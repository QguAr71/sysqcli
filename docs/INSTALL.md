# Instalacja szczegółowa

## Szybka

```bash
git clone https://github.com/SysQ-dev/sysqcli.git ~/.config/sysqcli
echo 'export SYSCLI_ROOT="$HOME/.config/sysqcli"' >> ~/.zshrc
echo 'source "$SYSCLI_ROOT/init.zsh"' >> ~/.zshrc
exec zsh
```

## Instalacja zależności

Po pierwszym uruchomieniu SysQCLI sprawdzi, czego brakuje. Wpisz:

```bash
qinstall
```

To zainstaluje z `pacman`:
- `fzf`, `zoxide`, `micro`, `bat`, `lsd`, `fastfetch`, `ripgrep`, `fd`

Oraz poinformuje o pakietach AUR:
- `zinit-git` (opcjonalne)
- `zsh-autosuggestions` (opcjonalne)

## Instalacja ręczna (krok po kroku)

```bash
# 1. Zależności
sudo pacman -S --needed fzf zoxide micro bat lsd fastfetch ripgrep fd

# 2. Opcjonalne
sudo pacman -S --needed ollama grc cpupower
yay -S zinit-git zsh-autosuggestions

# 3. Sklonuj
git clone https://github.com/SysQ-dev/sysqcli.git ~/.config/sysqcli

# 4. Podepnij do .zshrc
echo 'export SYSCLI_ROOT="$HOME/.config/sysqcli"' >> ~/.zshrc
echo 'source "$SYSCLI_ROOT/init.zsh"' >> ~/.zshrc

# 5. Restart
exec zsh
```

## Odinstalowanie

```bash
rm -rf ~/.config/sysqcli
# Usuń linie SYSCLI_ROOT z ~/.zshrc
sed -i '/SYSCLI_ROOT/d;/sysqcli/d' ~/.zshrc
exec zsh
```

## Uprawnienia

Niektóre funkcje wymagają `sudo` bez hasła:
- `turbo` / `eco` — cpupower
- `clean` — paccache, journalctl
- `up` — pacman

Dodaj do `/etc/sudoers` (przez `visudo`):

```
%wheel ALL=(ALL) NOPASSWD: /usr/bin/pacman, /usr/bin/cpupower, /usr/bin/paccache, /usr/bin/journalctl
```

Bez tego SysQCLI nadal działa — tylko zapyta o hasło.
