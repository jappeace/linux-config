;;; emacs.el --- Personal editor configuration -*- lexical-binding: nil; -*-

;; Keep the existing dynamic-binding semantics explicit for Emacs 31.
;; globals
;; (set-default 'truncate-lines nil)
(setq-default indent-tabs-mode nil) ;; disable tabs
(setq-default tab-width 2)
(setq version-control t )		; use version control
(setq vc-follow-symlinks t )				       ; don't ask for confirmation when opening symlinked file
(setq auto-save-file-name-transforms '((".*" "~/.emacs.d/auto-save-list/" t)) ) ;transform backups file name
(setq inhibit-startup-screen t )	; inhibit useless and old-school startup screen
(setq ring-bell-function 'ignore )	; silent bell when you make a mistake
(setq coding-system-for-read 'utf-8 )	; use utf-8 by default
(setq coding-system-for-write 'utf-8 )
(setq sentence-end-double-space nil)	; sentence SHOULD end with only a point.
(setq default-fill-column 85)		; toggle wrapping text at the 80th character
(setq initial-scratch-message "Good day sir, your wish is my command.") ; Emacs shows its subservience. Machines are tools.
(setq create-lockfiles nil) ;; this clashes with projectile
(setq tags-revert-without-query 1)
(setq auto-save-default nil)
(setq org-src-preserve-indentation t)
(advice-add 'risky-local-variable-p :override #'ignore) ;; allow remembering of risky vars https://emacs.stackexchange.com/questions/10983/remember-permission-to-execute-risky-local-variables


;; backup https://stackoverflow.com/questions/151945/how-do-i-control-how-emacs-makes-backup-files
(setq vc-make-backup-files t)
(setq kept-new-versions 10  ;; Number of newest versions to keep.
      kept-old-versions 0   ;; Number of oldest versions to keep.
      delete-old-versions t ;; Don't ask to delete excess backup versions.
      backup-by-copying t)  ;; Copy all files, don't rename them.
;; Default and per-save backups go here:
(setq backup-directory-alist '(("" . "~/.emacs.d/backup/per-save")))

(defun force-backup-of-buffer ()
  ;; Make a special "per session" backup at the first save of each
  ;; emacs session.
  (when (not buffer-backed-up)
    ;; Override the default parameters for per-session backups.
    (let ((backup-directory-alist '(("" . "~/.emacs.d/backup/per-session")))
          (kept-new-versions 3))
      (backup-buffer)))
  ;; Make a "per save" backup on each save.  The first save results in
  ;; both a per-session and a per-save backup, to keep the numbering
  ;; of per-save backups consistent.
  (let ((buffer-backed-up nil))
    (backup-buffer)))
(add-hook 'before-save-hook  'force-backup-of-buffer)

;; font
(push '(font . "firacode-12") default-frame-alist)

;; me me me https://www.youtube.com/watch?v=1oQWvoXMWME
(setq user-full-name "Jappie J. T. Klooster"
      user-mail-address "jappieklooster@hotmail.com"
      calendar-latitude 52.782
      calendar-longitude 6.331
      calendar-location-name "Ooienvaarstraat 38, Kampen")

;; use windows logo as meta, alt is used by i3
(setq x-super-keysym 'meta)

;; Annoying random freezes
(setq x-select-enable-clipboard-manager nil)

;;; I'm not a mouse peasant (disable menu/toolbars)
;; Guarded because each of these only exists in a build with the matching
;; toolkit. On emacs-unstable-pgtk, what emacs.nix builds, all three are
;; there and this is the plain three calls it always was. Elsewhere a void
;; function here aborts the rest of the file: emacs -Q --batch has no
;; tool-bar-mode and emacs-nox has no scroll-bar-mode, which made the config
;; impossible to load headlessly and so impossible to test.
(dolist (mouse-peasantry '(tool-bar-mode menu-bar-mode scroll-bar-mode))
  (if (fboundp mouse-peasantry)
      (funcall mouse-peasantry -1)
    nil))

(global-hl-line-mode +1) ;; highlight current line

;; initialize package
(eval-when-compile
  (require 'use-package))

(global-display-line-numbers-mode)

;;; theme
(use-package monokai-theme
  :load-path "themes"
  :config
  (load-theme 'monokai t)
  )

(use-package modus-themes
  :load-path "themes"
  :config
  ;; (load-theme 'modus-operandi-tinted t)
  )


(defun set-emacs-theme-light ()
  (interactive)

  (disable-theme "monokai")
  (load-theme 'modus-operandi-tinted t)

  (set-emacs-frames "light"))

(defun set-emacs-theme-dark ()
  (interactive)
  (disable-theme "modus-operandi-tinted")
  (load-theme 'monokai t)
  (set-emacs-frames "dark"))

;; Decision: undo-tree (unmaintained since 2021) is replaced by the
;; built-in undo-redo system (emacs 28+) as evil's undo backend, with
;; vundo (maintained, GNU ELPA) only for the tree visualizer, which
;; has no built-in equivalent. Known regression: undo history no
;; longer persists across sessions (undo-tree-history-directory-alist
;; did that); add undo-fu-session if it turns out to be missed.
(use-package vundo
  :commands (vundo))
;; load packages
(use-package evil
  :init
  (setq evil-want-keybinding nil)
  (setq evil-want-integration t)
  (setq evil-undo-system 'undo-redo)
  (setq evil-shift-width 2)
  :config
  (evil-mode 1)
  )

(use-package smartparens)
(use-package nyan-mode)
(use-package cider)
(use-package clojure-mode)

(use-package evil-escape
  :commands (evil-escape) ;; load it after press
  :after evil)
(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

;; I need to save kmacro-name-last-macro
;; and then I can insert insert-kbd-macro
;; which generates code like this (which can be used in general):
(fset 'macro-anki-2 ;; df;A;px0df A px0j
      (kmacro-lambda-form [?d ?f ?\; ?A ?\; escape ?p ?x ?0 ?d ?f ?  ?A ?  escape ?p ?x ?0 ?j] 0 "%d"))

;;; keybindings
(use-package general
  :config
  (general-define-key "<escape>" 'evil-escape) ;; escape anything
  (general-define-key
   :keymaps 'transient-base-map
   "<escape>" 'transient-quit-one)
  (general-define-key "C-'" 'avy-goto-word-1)
  (general-define-key "C-x b" 'consult-buffer)
  (general-define-key "M-i" nil) ;; disable space insertion on opening new window. (this is already used by sway)
  (general-define-key
   :keymaps 'normal
   ;; simple command
   "K" 'newline)

  (general-define-key
   :keymaps '(normal visual insert emacs)
   :prefix "SPC"
   :non-normal-prefix "C-SPC"

   "/"   'consult-ripgrep
   "k"   '(project-kill-buffers :which-key "kill project buffers") ;; sometimes projectile gets confused about temp files, this fixes that
   "SPC" '(avy-goto-word-or-subword-1  :which-key "go to char")
   "b"  'consult-buffer  ; change buffer, chose using ivy
   "e" '(:ignore t :which-key "eglot/gpg")
   "eg"  'epa-file-select-keys ; allows you to select encryption keys from gpg
   "ec"  'eglot-code-actions ; allows you to select encryption keys from gpg
   "c"  'eglot-code-actions ; allows you to select encryption keys from gpg

   "u"  'vundo
   "!"  'shell
   "j"  'xref-find-definitions ; lsp find definition
   "J"  '(:ignore t :which-key "jump")
   "cp" '(:ignore t :which-key "prompt")
   "Jx" 'xref-find-definitions
   "Jg" 'agda2-goto-definition-keyboard
   "x"  'xref-find-references ; find usages
   "l"  'list-processes
   "t"  '(:ignore t :which-key "toggles")
   "tl"   'set-emacs-theme-light
   "td"   'set-emacs-theme-dark
   "f"   '(:ignore t :which-key "find/format/file")
   "ff"  'format-all-buffer
   "fi"  'project-find-file
   "fr"  'project-query-replace-regexp
   "fg"  'counsel-git-grep
   "fh"  'haskell-hoogle-lookup-from-local
   "fl"  'consult-line
   "f/"   'consult-ripgrep
   "fc"  'dired-copy-filename-as-kill
   "fp"  'consult-project-buffer
   "h"   '(:ignore t :which-key "hoogle/inspection")
   "hl"  'haskell-hoogle-lookup-from-local
   "hq"  'haskell-hoogle
   "hs"  'haskell-mode-stylish-buffer
   "s"  '(:ignore t :which-key "spell/save")
   "ss"  'save-some-buffers
   "sc"  'flyspell-correct-word-before-point
   "p"  'project-find-file
   "o"  'project-switch-project
   "r"   'revert-buffer
   "q"  '(:ignore t :which-key "quitting")
   "qq"   'kill-emacs
   "g"   '(:ignore t :which-key "git")
   "gg"  'magit-status
   ;; "gf"  '(counsel-git :which-key "find file in git dir")
   "gf"  'magit-pull-from-upstream
   "gs"  'magit-status
   "gp"  'magit-push-popup ;; these days I often have to choose
   "gb"  'magit-blame
   "gl"  'magit-log-popup
   "gM"  'magit-remote-popup
   "gr"  'magit-rebase
   "gy"  'magit-show-refs
   "gc"  'magit-commit-popup
   "gC"  'magit-cherry-pick-popup
   "gz"  'magit-stash-popup
   ;; Applications
   "al" 'macro-anki-2
   "a" '(:ignore t :which-key "Applications")
   "d" 'insert-date
   ";" 'comment-line
   "ar" 'dirvish
   ))

(use-package package-lint
  :commands  (package-lint-current-buffer
              package-lint-buffer))


                                        ; loooks pretty good butt.. another time
                                        ; https://github.com/lassik/emacs-format-all-the-code
(use-package format-all ;;
                                        ; -- the haskell mode hook jumps to the top of screen on save
                                        ; :hook (haskell-mode . format-all-mode) ; TODO fixed in https://github.com/lassik/emacs-format-all-the-code/issues/23
  :commands (
             format-all-mode
             format-all-buffer
             )
  )

(use-package flx)

;; Decision: oil.nvim-style file creation uses a magit-commit-style
;; popup buffer instead of editing the listing in place. In-place
;; editing was tried first and fails in real dirvish sessions: dirvish
;; re-asserts read-only from its render hooks so typed names are
;; rejected, and stray keys then run as dired commands (flagging files
;; for deletion). grease.el replaces the whole file manager view for
;; exactly this reason; the popup keeps dirvish untouched. wdired was
;; also considered but can only rename, not create.
(defvar-local dirvish-oil-target-directory nil
  "Directory `dirvish-oil-commit' creates entries in.
Buffer-local to the *dirvish-oil* popup, set when it opens.")

(defvar-local dirvish-oil-listing-buffer nil
  "The dired buffer to revert after `dirvish-oil-commit'.
Buffer-local to the *dirvish-oil* popup, set when it opens.")

;; fundamental-mode parent: text-mode hooks (flyspell) make no sense
;; on file names
(define-derived-mode dirvish-oil-edit-mode fundamental-mode "dirvish-oil"
  "Type file names, one per line; C-c C-c creates them, C-c C-k cancels."
  (setq header-line-format
        "one name per line, trailing / = directory, C-c C-c create, C-c C-k cancel"))

(define-key dirvish-oil-edit-mode-map (kbd "C-c C-c") #'dirvish-oil-commit)
(define-key dirvish-oil-edit-mode-map (kbd "C-c C-k") #'dirvish-oil-cancel)

(defun dirvish-oil-insert ()
  "Pop a small buffer to create files in the listed directory.
One name per line; a trailing / makes a directory, parent directories
are created as needed. C-c C-c creates everything, C-c C-k cancels."
  (interactive)
  (let ((target (dired-current-directory))
        (listing (current-buffer))
        (popup (get-buffer-create "*dirvish-oil*")))
    (with-current-buffer popup
      (erase-buffer)
      ;; major mode first: it kills local variables
      (dirvish-oil-edit-mode)
      (setq dirvish-oil-target-directory target)
      (setq dirvish-oil-listing-buffer listing))
    (pop-to-buffer popup '((display-buffer-below-selected)
                           (window-height . 6)))
    (evil-insert-state)))

(defun dirvish-oil-commit ()
  "Create every non-empty line of the popup, then close it."
  (interactive)
  (let ((target dirvish-oil-target-directory)
        (listing dirvish-oil-listing-buffer))
    (dolist (line (split-string (buffer-string) "\n"))
      (dirvish-oil-create-entry (string-trim line) target))
    (dirvish-oil-cancel)
    (if (buffer-live-p listing)
        (with-current-buffer listing
          (revert-buffer))
      nil)))

(defun dirvish-oil-cancel ()
  "Close the popup without creating anything further."
  (interactive)
  (kill-buffer "*dirvish-oil*"))

(defun dirvish-oil-create-entry (name target-directory)
  "Create NAME inside TARGET-DIRECTORY.
A trailing / creates a directory, otherwise an empty file (parent
directories are created as needed). An existing file is an error,
never truncated: make-empty-file skips its own existence check when
PARENTS is non-nil and would silently empty the file."
  (if (string-empty-p name)
      nil
    (let ((target (expand-file-name name target-directory)))
      (if (string-suffix-p "/" name)
          (make-directory target t)
        (if (file-exists-p target)
            (error "dirvish-oil: %s already exists, refusing to truncate it" name)
          (make-empty-file target t))))))

;; Decision: ranger-style copy/paste needs a clipboard that survives
;; navigating between directories, so dirvish-file-clipboard is a
;; global variable, the same shape as ranger's copy ring or emacs'
;; own kill-ring. Using the dired marks directly as the clipboard
;; (dirvish-yank's model: paste acts on whatever is marked right now)
;; was tried first and rejected: ranger fingers expect an explicit
;; yank step, and a snapshot doesn't shift under you when marks
;; change between yank and paste.
(defvar dirvish-file-clipboard nil
  "Absolute file names captured by `dirvish-yank-to-clipboard'.
`dirvish-paste-clipboard' copies them into the listed directory.")

(defun dirvish-yank-to-clipboard ()
  "Put the marked files on `dirvish-file-clipboard' (ranger's yy).
With nothing marked the file at point is yanked instead. The
clipboard survives navigation: yank here, walk somewhere else with
h/l, paste with p."
  (interactive)
  (setq dirvish-file-clipboard (dired-get-marked-files))
  (message "dirvish: yanked %s"
           (mapconcat #'file-name-nondirectory dirvish-file-clipboard ", ")))

(defun dirvish-refresh-listing ()
  "Re-read the directory this listing shows, from disk (gr, or <f5>).
Use after something changed the directory behind dirvish' back: a git
pull in a terminal, a build, an rm.

Passes IGNORE-AUTO explicitly rather than calling `revert-buffer' bare.
dirvish caches per-file data (sizes, attributes) next to the listing and
`dirvish-revert' only drops that cache when IGNORE-AUTO is set, which
`revert-buffer' fills in from `current-prefix-arg' when a human invokes
it and leaves nil when elisp calls it. Naming the command means the key
and `dirvish-paste-clipboard' get the same full refresh."
  (interactive)
  (revert-buffer t t))

(defun dirvish-paste-collides-p (source-file target-directory)
  "Non-nil when pasting SOURCE-FILE into TARGET-DIRECTORY hits an existing name.
Pasting a file back into its own directory is the common case: the
target name is the source itself."
  (file-exists-p (expand-file-name (file-name-nondirectory source-file)
                                   target-directory)))

(defun dirvish-paste-free-name (source-file target-directory)
  "Absolute path in TARGET-DIRECTORY for a copy of SOURCE-FILE nothing occupies.
Appends -copy before the extension, so template.txt becomes
template-copy.txt, then template-copy-2.txt and upwards while those are
taken too. The extension is kept so the copy still opens in the mode the
original did."
  (let* ((stem (file-name-base source-file))
         (extension (or (file-name-extension source-file t) ""))
         (candidate (expand-file-name (concat stem "-copy" extension)
                                      target-directory))
         (attempt 2))
    (while (file-exists-p candidate)
      (setq candidate (expand-file-name
                       (format "%s-copy-%d%s" stem attempt extension)
                       target-directory))
      (setq attempt (1+ attempt)))
    candidate))

(defun dirvish-paste-as-new-name (source-file target-directory)
  "Ask for a name and copy SOURCE-FILE into TARGET-DIRECTORY under it.
The prompt is prefilled with the old name so it can be edited in
place: yank a file, paste it where it already lives, tweak the name,
and the old file serves as a template for the new one. Keeps asking
while the chosen name is already taken; C-g aborts."
  (let ((new-name (read-string
                   (format "dirvish: %s exists here, paste as: "
                           (file-name-nondirectory source-file))
                   (file-name-nondirectory source-file))))
    (if (file-exists-p (expand-file-name new-name target-directory))
        (progn
          (message "dirvish: %s is also taken, pick another name" new-name)
          (sit-for 1)
          (dirvish-paste-as-new-name source-file target-directory))
      ;; dired-copy-file instead of copy-file: it recurses into
      ;; directories (dired-recursive-copies) so a yanked folder can be
      ;; templated the same way
      (dired-copy-file source-file
                       (expand-file-name new-name target-directory)
                       nil))))

(defun dirvish-paste-clipboard (&optional ask-for-name)
  "Copy the clipboard files into the listed directory (ranger's pp).
The clipboard is kept afterwards so one yank can paste repeatedly.

A file whose name is already taken here, which is what pasting into the
directory it was yanked from means, is copied under a generated free
name: template.txt lands as template-copy.txt. Nothing is overwritten
and no name is asked for.

Pasting a directory is the one case that still stops: `dired-copy-file'
asks for confirmation of the recursive copy unless `dired-recursive-copies'
is set to always, and it defaults to top. That confirmation guards every
dired copy of a directory, it is not something this command adds, and it
is left in place.

With a prefix argument the name is asked for instead, prefilled with the
old one so it can be edited in place, see `dirvish-paste-as-new-name'.
That is the way to use a yanked file as the template for a differently
named one, which is worth a prompt because only the human knows the name.

Collision-free files run through the dirvish-yank machinery: an async
child emacs, progress in the mode line."
  (interactive "P")
  (require 'dirvish-yank)
  (if (null dirvish-file-clipboard)
      (user-error "dirvish: file clipboard is empty, yank files with yy first")
    (let* ((target-directory (expand-file-name (dired-current-directory)))
           (colliding (seq-filter
                       (lambda (source-file)
                         (dirvish-paste-collides-p source-file target-directory))
                       dirvish-file-clipboard))
           (collision-free (seq-remove
                            (lambda (source-file)
                              (dirvish-paste-collides-p source-file target-directory))
                            dirvish-file-clipboard))
           (generated-names nil))
      ;; Sequential on purpose: each copy exists by the time the next
      ;; free name is picked, so two files yanked under the same name do
      ;; not both get handed template-copy.txt.
      (dolist (source-file colliding)
        (if ask-for-name
            (dirvish-paste-as-new-name source-file target-directory)
          (let ((free-name (dirvish-paste-free-name source-file target-directory)))
            ;; dired-copy-file, not copy-file: it recurses into
            ;; directories (dired-recursive-copies) so a yanked folder
            ;; pastes as a folder
            (dired-copy-file source-file free-name nil)
            (push (file-name-nondirectory free-name) generated-names))))
      ;; only the copies above need this refresh: the async dirvish-yank
      ;; handler below reverts by itself on completion
      (if colliding
          (dirvish-refresh-listing)
        nil)
      (if generated-names
          (message "dirvish: pasted as %s"
                   (mapconcat #'identity (nreverse generated-names) ", "))
        nil)
      (if collision-free
          (dirvish-yank-default-handler
           'dired-copy-file collision-free target-directory)
        nil))))

;; Decision: nothing watches git for us. Listings stay fresh through
;; dired-auto-revert-buffer (re-read on revisit) and
;; `dirvish-refresh-listing' on gr or <f5> for an explicit refresh.
;;
;; A third layer used to sit on top: a global core.hooksPath whose
;; post-merge/post-checkout/post-rewrite/post-applypatch hooks called a
;; jappie-dired-revert-all over emacsclient, so every open listing
;; refreshed the moment git touched the worktree. Removed, it cost more
;; than the staleness it fixed. Two reasons, worth writing down so it
;; does not get reinvented:
;;
;;   - it reverted every dired buffer in the session, synchronously,
;;     while git waited on the emacsclient call. dirvish keeps a buffer
;;     per directory visited, so a day of browsing turns one git pull
;;     into dozens of directory re-reads.
;;   - run from magit it re-enters: emacs is blocked on the git
;;     subprocess, the hook calls back into that same emacs over
;;     emacsclient, and nothing can answer until the git command that
;;     is waiting for the answer finishes.
;;
;; The polling alternative is no better: global-auto-revert-non-file-buffers
;; stats every listing on a timer and still lags seconds behind the pull.
;; A stale listing is a gr away, which is the cheap fix.

(defun dirvish-toggle-mark ()
  "Toggle the dired mark of the file at point, then move down a line.
dired has mark (m) and unmark (u) but no single-file toggle; its t
inverts every mark in the buffer, which is never what a ranger hand
means by t."
  (interactive)
  (if (eq (char-after (line-beginning-position)) dired-marker-char)
      (dired-unmark 1)
    (dired-mark 1)))

;; Decision: dirvish replaces ranger for file navigation. ranger.el
;; reimplements dired (windows, previews, its own minor modes) and is
;; unmaintained, which is where its bugs came from. dirvish is a layer
;; on top of stock dired, so navigation and file operations are the
;; battle-tested built-ins and dirvish only adds layout and previews.
;; Also considered: plain dired + dired-preview (fewer features) and
;; treemacs (sidebar tree, different workflow than ranger-style
;; browsing).
(use-package dirvish
  :commands (dirvish)
  :init
  ;; make plain dired buffers use dirvish too
  (dirvish-override-dired-mode)
  :config
  (setq
   ;; (DEPTH MAX-PARENT-WIDTH PREVIEW-WIDTH). depth 0 means no parent
   ;; pane (was ranger-parent-depth 0) and makes the middle value
   ;; unused; preview takes 60%, the current pane gets the rest.
   dirvish-default-layout '(0 0.4 0.6)
   ;; was ranger-excluded-extensions, merged with dirvish's own
   ;; defaults (bin exe gpg elc eln). Matching uses only the last
   ;; extension component, so "gz" is what covers tar.gz files.
   ;; The old nix "result" symlink hack (faking a nix-result extension
   ;; via advice on file-name-extension) is gone: dirvish previews
   ;; directories as listings and shows a placeholder for binaries
   ;; instead of dumping them in a buffer.
   dirvish-preview-disabled-exts '("bin" "exe" "gpg" "elc" "eln" "gz" "mkv" "iso" "mp4")
   ;; re-read the listing from disk when revisiting a dired buffer, so
   ;; walking away and back never shows a stale directory
   dired-auto-revert-buffer t
   )
  ;; ranger-style navigation. ranger.el shipped its own vim keymap;
  ;; dirvish inherits dired's, where evil keeps h/l as char motions.
  (evil-define-key 'normal dirvish-mode-map
    ;; dired's own t is dired-toggle-marks, which inverts every mark
    ;; in the buffer; ranger's t toggled only the file at point, which
    ;; is what fingers expect. Invert-all stays reachable on * t.
    "t" 'dirvish-toggle-mark
    "h" 'dired-up-directory
    "l" 'dired-find-file
    ;; menu of dirvish commands; its "c" entry is a dired cheatsheet
    ;; (create dir, rename, copy, marks etc). Shadows evil's backward
    ;; search, which is no loss in a file listing.
    "?" 'dirvish-dispatch
    ;; manual refresh for when the directory changed under the listing
    ;; (a git pull in a terminal, rm, a build). gr is the evil
    ;; convention for revert, <f5> is the one every other program uses
    ;; and needs no modifier. This is the only refresh that is not tied
    ;; to revisiting a buffer, see the comment above about the git hook
    ;; that used to push one.
    "gr" 'dirvish-refresh-listing
    (kbd "<f5>") 'dirvish-refresh-listing
    ;; i as in insert: pops the file creation buffer, see
    ;; dirvish-oil-insert. Shadows plain insert state, which is useless
    ;; in a read-only listing anyway (wdired via C-x C-q still works
    ;; for renames).
    "i" 'dirvish-oil-insert
    ;; ranger-style copy/paste: yy snapshots the marked files (or the
    ;; file at point) onto dirvish-file-clipboard, p copies them into
    ;; the directory shown here. yy shadows the evil yank operator and
    ;; p shadows evil-paste-after, both useless in a read-only listing.
    "yy" 'dirvish-yank-to-clipboard
    "p" 'dirvish-paste-clipboard
    ;; menu with the other paste flavours (move, symlink, hardlink,
    ;; relative symlink), from the dirvish-yank extension. These act on
    ;; the dired marks, not on dirvish-file-clipboard: mark with t,
    ;; walk to the target directory, Y m moves the marked files here.
    ;; Also reachable as ? y. Shadows evil-yank-line, useless in a
    ;; read-only listing.
    "Y" 'dirvish-yank-menu)
  )

;;; show what keys are possible
(use-package which-key
  :config
  (setq which-key-idle-delay 0.01)
  (which-key-mode)
  )

;;; jump around
(use-package avy
  :commands (avy-goto-word-1 avy-goto-word-or-subword-1)
  :config
  (setq avy-all-windows 'all-frames)
  )


;;; git
(use-package magit
  :defer
  :commands
  (magit-blame
   magit-branch-popup
   magit-cherry-pick-popup
   magit-commit-popup
   magit-log-popup
   magit-pull-from-upstream
   magit-push-popup
   magit-push-to-remote
   magit-remote-popup
   magit-show-refs
   magit-stash-popup
   magit-status
   magit-rebase
   )
  )

;;; I can't spell
(use-package flyspell
  :defer t
  :ensure nil
  :init
  (progn
    (add-hook 'prog-mode-hook 'flyspell-prog-mode)
    (add-hook 'text-mode-hook 'flyspell-mode)
    )
  :config
  (setq ispell-dictionary "american")
  )

;;; more info
(use-package powerline
  :config
  (powerline-default-theme)
  )

;;; nix syntax highlighting
(use-package nix-mode)

(use-package yaml-mode
  :mode "\\.yaml\\'")
(use-package markdown-mode
  :mode "\\.md\\'")

;;; JS
;; Decision: rjsx-mode (dead since 2020) removed in favor of built-in
;; js-mode, which has handled JSX since emacs 27 and is the default
;; for .js already.

(use-package shakespeare-mode)

;;; python
(use-package python
  :mode ("\\.py\\'" . python-mode)
  :interpreter ("python" . python-mode))

(add-hook 'haskell-mode-hook
          (function (lambda ()
                      (setq evil-shift-width 2))))

;;; Haskell
(use-package haskell-mode
  :after evil
  :hook
  (haskell-mode . interactive-haskell-mode)
  :custom
  ;; (haskell-font-lock-symbols t)
  (haskell-process-auto-import-loaded-modules t)
  (haskell-process-log t)
  (haskell-tags-on-save nil)
  :config
  (custom-set-variables
   ;; '(haskell-font-lock-symbols t)
   '(haskell-stylish-on-save nil)
   )
  (defun haskell-evil-open-above ()
    (interactive)
    (evil-digit-argument-or-evil-beginning-of-line)
    (haskell-indentation-newline-and-indent)
    (evil-previous-line)
    (haskell-indentation-indent-line)
    (evil-append-line nil))

  (defun haskell-evil-open-below ()
    (interactive)
    (evil-append-line nil)
    (haskell-indentation-newline-and-indent))

  (evil-define-key 'normal haskell-mode-map
    "o" 'haskell-evil-open-below
    "O" 'haskell-evil-open-above)
  :custom
  (haskell-font-lock-symbols t)
  )



(use-package evil-org
  :disabled
  )
(use-package ox-reveal
  :disabled
  )

(defun mah-symbols ()
  "Better custom symbols using safe hex codes."
  (setq prettify-symbols-alist
        '(("<=<"  . ?\x1f41f)  ;; 🐟 (U+1F41F)
          ("TODO" . ?\x1f527)))) ;; 🔧 (U+1F527)

(add-hook 'prog-mode-hook #'mah-symbols)

(add-hook 'prog-mode-hook #'prettify-symbols-mode)

(use-package yasnippet
  :after lsp-mode
  )
(use-package rust-mode
  :config
  ;; install toolchain (rustup toolchain install stable)
  ;; install https://crates.io/crates/rustfmt-nightly
  (setq rust-format-on-save t)
  )
(use-package flycheck-rust
  :after rust-mode
  :config
  (add-hook 'flycheck-mode-hook #'flycheck-rust-setup)
  )
;; use emacs as mergetool
(defvar ediff-after-quit-hooks nil
  "* Hooks to run after ediff or emerge is quit.")

(defadvice ediff-quit (after edit-after-quit-hooks activate)
  (run-hooks 'ediff-after-quit-hooks))

(setq git-mergetool-emacsclient-ediff-active nil)


(setq ediff-window-setup-function 'ediff-setup-windows-plain)
(setq ediff-split-window-function 'split-window-horizontally)

(defun local-ediff-before-setup-hook ()
  (setq local-ediff-saved-frame-configuration (current-frame-configuration))
  (setq local-ediff-saved-window-configuration (current-window-configuration))
  ;; (local-ediff-frame-maximize)
  (if git-mergetool-emacsclient-ediff-active
      (raise-frame)))

(defun local-ediff-quit-hook ()
  (set-frame-configuration local-ediff-saved-frame-configuration)
  (set-window-configuration local-ediff-saved-window-configuration))

(defun local-ediff-suspend-hook ()
  (set-frame-configuration local-ediff-saved-frame-configuration)
  (set-window-configuration local-ediff-saved-window-configuration))

(add-hook 'ediff-before-setup-hook 'local-ediff-before-setup-hook)
(add-hook 'ediff-quit-hook 'local-ediff-quit-hook 'append)
(add-hook 'ediff-suspend-hook 'local-ediff-suspend-hook 'append)

;; Useful for ediff merge from emacsclient.
(defun git-mergetool-emacsclient-ediff (local remote base merged)
  (setq git-mergetool-emacsclient-ediff-active t)
  (if (file-readable-p base)
      (ediff-merge-files-with-ancestor local remote base nil merged)
    (ediff-merge-files local remote nil merged))
  (recursive-edit))

(defun git-mergetool-emacsclient-ediff-after-quit-hook ()
  (exit-recursive-edit))

(add-hook 'ediff-after-quit-hooks 'git-mergetool-emacsclient-ediff-after-quit-hook 'append)

(defun insert-date (prefix)
  "Insert the current date. With prefix-argument, use ISO format. With
two prefix arguments, write out the day and month name."
  (interactive "P")
  (let ((format (cond
                 ((not prefix) "%Y.%m.%d")
                 ((equal prefix '(4)) "%Y-%m-%d")
                 ((equal prefix '(16)) "%A, %d. %B %Y")))
        (system-time-locale "de_DE"))
    (insert (format-time-string format))))


;; rule 80 chars, if issues: https://github.com/company-mode/company-mode/issues/180#issuecomment-55047120
;; https://emacs.stackexchange.com/questions/147/how-can-i-get-a-ruler-at-column-80
;; Decision: the fill-column-indicator package (dead since 2020) is
;; replaced by the built-in equivalent, available since emacs 27
(add-hook 'prog-mode-hook #'display-fill-column-indicator-mode)

(use-package ox-reveal)
;; https://emacs.stackexchange.com/questions/44361/org-mode-export-gets-weird-symbols-at-the-end-of-each-line-while-exporting-to-ht
(use-package htmlize
  :defer t
  :config
  (progn

    ;; (an fci-mode disable hack lived here; it left with the
    ;; fill-column-indicator package, whose overlay glyphs leaked into
    ;; htmlize output. The built-in indicator doesn't have that bug.)

    ;; `flyspell-mode' also has to be disabled because depending on the
    ;; theme, the squiggly underlines can either show up in the html file
    ;; or cause elisp errors like:
    ;; (wrong-type-argument number-or-marker-p (nil . 100))
    (with-eval-after-load 'flyspell
      (defvar modi/htmlize-initial-flyspell-state nil
        "Variable to store the state of `flyspell-mode' when `htmlize-buffer' is called.")

      (defun modi/htmlize-before-hook-flyspell-disable ()
        (setq modi/htmlize-initial-flyspell-state flyspell-mode)
        (when flyspell-mode
          (flyspell-mode -1)))

      (defun modi/htmlize-after-hook-flyspell-enable-maybe ()
        (when modi/htmlize-initial-flyspell-state
          (flyspell-mode 1)))

      (add-hook 'htmlize-before-hook #'modi/htmlize-before-hook-flyspell-disable)
      (add-hook 'htmlize-after-hook #'modi/htmlize-after-hook-flyspell-enable-maybe))))

(use-package php-mode
  :config
  ;; dante's xref doesn't work for mutli-project setups, we just use etags
  ;; (remove-hook 'xref-backend-functions 'dante--xref-backend)
  )



(use-package cobol-mode)
(use-package idris-mode)
(use-package lua-mode)
(use-package typescript-mode)

(use-package wgrep)

(use-package ws-butler
  :init
  (add-hook 'prog-mode-hook #'ws-butler-mode)
  )

;; Decision: the flymake-shellcheck package is dropped (archived; its
;; own README says unnecessary on emacs 29+): sh-mode registers a
;; shellcheck flymake backend itself, it only needs flymake-mode
;; enabled
(add-hook 'sh-mode-hook #'flymake-mode)

;;; this is an lsp client better then lsp-mode package
(use-package eglot
  :defer t
  :hook
  (haskell-mode . eglot-ensure)
  (nix-mode . eglot-ensure)
  :config
  (add-to-list 'eglot-server-programs '(nix-mode . ("nil")))
  (add-hook 'haskell-mode-hook 'eglot-ensure)
  (setq-default eglot-workspace-configuration
                '((haskell
                   (plugin
                    (stan
                     (globalOn . :json-false))))))  ;; disable stan
  :custom
  (eglot-autoshutdown t)  ;; shutdown language server after closing last file
  (eglot-confirm-server-initiated-edits nil)
  )

(use-package envrc
  :hook (prog-mode . envrc-mode)
  )

(use-package agda2-mode
    :mode "\\.lagda\\.md\\'"
          "\\.agda\\'"
  )


;; pulse frame completion
(use-package corfu
  :custom
  (corfu-auto-delay 0.2)
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-commit-predicate nil)
  (corfu-quit-at-boundary t)
  (corfu-quit-no-match t)
  (corfu-echo-documentation nil)
  :init
  (global-corfu-mode))

;; actual completion backend... so this does the work?
(use-package vertico
  :init
  (use-package orderless
    :commands (orderless)
    :custom (completion-styles '(orderless flex)))

  (use-package consult
    :init
    (setq consult-preview-key nil)
    :bind
    ("C-c r" . consult-recent-file)
    ("C-c f" . consult-ripgrep)
    ("C-c l" . consult-line)
    ("C-c i" . consult-imenu)
    ("C-c t" . gtags-find-tag)
    ("C-x b" . consult-buffer)
    ("C-c x" . consult-complex-command)
    (:map comint-mode-map
      ("C-c C-l" . consult-history)))
  :config
  (recentf-mode t)
  (vertico-mode t))

(use-package embark
  :ensure t

  :bind
  (("C-." . embark-act)         ;; pick some comfortable binding
   ("C-o" . embark-export)
   ("C-;" . embark-dwim)        ;; good alternative: M-.
   ("C-h B" . embark-bindings)) ;; alternative for `describe-bindings'

  :init

  ;; Optionally replace the key help with a completing-read interface
  (setq prefix-help-command #'embark-prefix-help-command)

  :config

  ;; Hide the mode line of the Embark live/completions buffers
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

;; Consult users will also want the embark-consult package.
(use-package embark-consult
  :ensure t
  :after (embark consult)
  :demand t ; only necessary if you have the hook below
  ;; if you want to have consult previews as you move around an
  ;; auto-updating embark collect buffer
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

(use-package elm-mode)
(use-package dockerfile-mode)
(use-package direnv)

(use-package dart-mode)

(use-package agenix)
