# runas-workspace

Izolowane środowiska pracy per klient na Arch Linux: każdy klient to osobny
użytkownik `systemd-homed` (szyfrowany katalog domowy), zmapowany na workspace
XFCE o tej samej nazwie. Komendy uruchamiane na danym workspace lecą jako
dedykowany użytkownik — z dźwiękiem, keyringiem i bez ciągłego pytania o hasło.

> **Zakres:** XFCE + X11 + systemd-homed. To osobisty workflow ubrany w pakiet,
> nie uniwersalne narzędzie. Nie działa na Wayland/GNOME/KDE bez przeróbek.

## Jak to działa

`su -l <klient>` przechodzi pełny stack PAM: aktywuje szyfrowany home, odblokowuje
keyring i stawia sesję usera. `enable-linger` utrzymuje ją przy życiu, więc kolejne
komendy wstrzykiwane przez `machinectl shell` trafiają do żywej sesji — bez hasła,
z działającym audio i keyringiem. Hasło pada raz na klienta na boot (to klucz
szyfrowania jego home).

## Instalacja (AUR / lokalnie)

```bash
# z AUR (po opublikowaniu):
#   yay -S runas-workspace-git
# lokalnie z repo:
makepkg -si
```

Warunek: jesteś w grupie `wheel` (na tym opiera się autoryzacja polkit; taki user
i tak może `sudo su - X`, więc to nie dodaje uprawnień).

Wrapper i audio działają od razu. Aby włączyć **odblokowanie keyringa jednym
hasłem** oraz **auto-wylogowanie klientów** przy Twoim logout, odpal jawnie:

```bash
sudo runas-setup            # odwrotnie: sudo runas-setup --undo
```

Ta komenda dopina moduły PAM (`/etc/pam.d/su` + PAM Twojego display managera).
Pakiet **nie** robi tego sam podczas instalacji — nie modyfikuje plików należących
do innych pakietów bez Twojej jawnej zgody. Wszystkie dopinane moduły są `optional`,
więc nie mogą zablokować logowania.

## Użycie

```bash
runas firefox        # na workspace 'klientA' -> Firefox jako klientA
```

Pierwszy raz wyskoczy pytanie o hasło klienta; potem cicho.

## Bezpieczeństwo — czytaj

To **granica UID**, nie sandbox. Chroni pliki, keyring i profil per klient (osobny
szyfrowany home). Ale:

- **X11 nie izoluje klientów.** `runas` wpuszcza usera klienta do Twojego serwera X
  przez `xhost +si:localuser:` (least-privilege, nie `xhost +`), i cofa to przy
  wylogowaniu. Mimo to, dopóki dostęp jest nadany, proces klienta może teoretycznie
  podsłuchiwać klawiaturę / zrzucać ekran innych okien. Jeśli potrzebujesz twardej
  izolacji wyświetlania — docelowo Wayland lub xpra per user.
- **Wspólny socket audio** (`/run/runas/pulse-<uid>`, `client.access=unrestricted`)
  jest osiągalny dla innych lokalnych UID-ów. W modelu „wszyscy userzy to Twoje
  własne konta" to nieistotne; w środowisku z obcymi użytkownikami lokalnymi —
  rozważ wyłączenie audio lub tunel per sesja.

## Odinstalowanie

```bash
sudo runas-setup --undo     # najpierw cofnij integrację PAM
sudo pacman -R runas-workspace-git
```

## Licencja

MIT.
