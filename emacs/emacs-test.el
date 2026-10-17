;;; emacs-test.el --- tests for the dirvish behaviour emacs.el adds -*- lexical-binding: t; -*-

;; Run with emacs/tests.nix:
;;
;;     nix-build emacs/tests.nix
;;
;; which loads the real emacs.el (through the same default.el the built
;; emacs ships) and then this file, so the tests exercise the config that
;; actually gets installed rather than a copy of it.
;;
;; Scope: the dirvish behaviour emacs.el adds on top of the package. The
;; paste logic for ranger-style yy/p (pick a free name, never overwrite,
;; keep counting while names are taken), the cache busting behind gr and
;; revisits, and the ; prefix, which is driven by its keys because the
;; binding composing with evil and dired-mode-map is the whole feature.
;; The rest of the file is package configuration, where the value is in
;; whether emacs starts, not in an assertion.

(require 'ert)
(require 'dired)

(defmacro dirvish-test-in-directory (bindings &rest body)
  "Run BODY in a dired buffer on a fresh temporary directory.
BINDINGS is a list of (RELATIVE-NAME . CONTENT) files created there
first. The directory is the current dired listing and is deleted
afterwards, so a test never sees another test's files."
  (declare (indent 1))
  `(let* ((directory (file-name-as-directory (make-temp-file "dirvish-test" t)))
          (dirvish-file-clipboard nil))
     (unwind-protect
         (progn
           (dolist (file ,bindings)
             (with-temp-file (expand-file-name (car file) directory)
               (insert (cdr file))))
           (with-current-buffer (dired-noselect directory)
             (unwind-protect
                 (progn ,@body)
               (kill-buffer))))
       (delete-directory directory t))))

(defmacro dirvish-test-in-session (bindings &rest body)
  "Run BODY in a full dirvish session on a fresh temporary directory.
BINDINGS are files as in `dirvish-test-in-directory'. Unlike that macro
the listing is opened by the dirvish command, in the selected window with
its preview pane, so keys and previews behave as they do interactively.
BODY sees the directory as `directory' and the session as `session'."
  (declare (indent 1))
  `(let ((directory (file-name-as-directory (make-temp-file "dirvish-test" t))))
     (unwind-protect
         (progn
           (dolist (file ,bindings)
             (with-temp-file (expand-file-name (car file) directory)
               (insert (cdr file))))
           (dirvish directory)
           (let ((session (dirvish-curr)))
             ;; interactively redisplay builds the layout; batch emacs
             ;; never redisplays
             (dirvish--build-layout session)
             (unwind-protect
                 (progn ,@body)
               (dirvish-quit))))
       (delete-directory directory t))))

(defun dirvish-test-preview-text (session)
  "Return the text SESSION's preview pane shows."
  (with-current-buffer (window-buffer (dv-preview-window session))
    (buffer-string)))

(defun dirvish-test-contents (path)
  "Return the contents of PATH as a string."
  (with-temp-buffer
    (insert-file-contents path)
    (buffer-string)))

(ert-deftest dirvish-paste-free-name-appends-copy ()
  "The first free name for a taken file is the stem plus -copy."
  (dirvish-test-in-directory '(("template.txt" . "content"))
    (should (equal (file-name-nondirectory
                    (dirvish-paste-free-name
                     (expand-file-name "template.txt" directory) directory))
                   "template-copy.txt"))))

(ert-deftest dirvish-paste-free-name-counts-past-taken-names ()
  "Names already on disk are skipped, counting upwards from 2."
  (dirvish-test-in-directory '(("template.txt" . "a")
                               ("template-copy.txt" . "b")
                               ("template-copy-2.txt" . "c"))
    (should (equal (file-name-nondirectory
                    (dirvish-paste-free-name
                     (expand-file-name "template.txt" directory) directory))
                   "template-copy-3.txt"))))

(ert-deftest dirvish-paste-free-name-keeps-the-extension ()
  "The suffix goes before the extension, so the copy opens in the same mode."
  (dirvish-test-in-directory '(("script.sh" . "#!/bin/sh"))
    (should (equal (file-name-nondirectory
                    (dirvish-paste-free-name
                     (expand-file-name "script.sh" directory) directory))
                   "script-copy.sh")))
  (dirvish-test-in-directory '(("README" . "no extension"))
    (should (equal (file-name-nondirectory
                    (dirvish-paste-free-name
                     (expand-file-name "README" directory) directory))
                   "README-copy"))))

(ert-deftest dirvish-paste-clipboard-copies-under-a-free-name ()
  "Pasting into the directory a file came from copies it, it does not overwrite.
Drives the real command, so this covers the collision branch picking a
name and the copy actually landing on disk."
  (dirvish-test-in-directory '(("template.txt" . "original"))
    (setq dirvish-file-clipboard (list (expand-file-name "template.txt" directory)))
    (dirvish-paste-clipboard)
    (should (equal (dirvish-test-contents (expand-file-name "template.txt" directory))
                   "original"))
    (should (equal (dirvish-test-contents (expand-file-name "template-copy.txt" directory))
                   "original"))))

(ert-deftest dirvish-paste-clipboard-repeats-without-overwriting ()
  "One yank pasted three times leaves three copies, not one rewritten copy.
This is the regression that matters: an implementation that reused the
same generated name would pass the single-paste test and lose files here."
  (dirvish-test-in-directory '(("template.txt" . "original"))
    (setq dirvish-file-clipboard (list (expand-file-name "template.txt" directory)))
    (dirvish-paste-clipboard)
    (dirvish-paste-clipboard)
    (dirvish-paste-clipboard)
    (dolist (expected '("template.txt" "template-copy.txt"
                        "template-copy-2.txt" "template-copy-3.txt"))
      (should (equal (dirvish-test-contents (expand-file-name expected directory))
                     "original")))))

(ert-deftest dirvish-paste-clipboard-asks-when-given-a-prefix-argument ()
  "With a prefix argument the name comes from the prompt, not from the generator."
  (dirvish-test-in-directory '(("template.txt" . "original"))
    (setq dirvish-file-clipboard (list (expand-file-name "template.txt" directory)))
    (cl-letf (((symbol-function 'read-string)
               (lambda (&rest _) "named-by-hand.txt")))
      (dirvish-paste-clipboard t))
    (should (equal (dirvish-test-contents
                    (expand-file-name "named-by-hand.txt" directory))
                   "original"))
    (should-not (file-exists-p (expand-file-name "template-copy.txt" directory)))))

(ert-deftest dirvish-paste-clipboard-refuses-an-empty-clipboard ()
  "Pasting with nothing yanked says so instead of failing obscurely."
  (dirvish-test-in-directory '(("template.txt" . "original"))
    (should-error (dirvish-paste-clipboard) :type 'user-error)))

;; Note [dirvish caches] in emacs.el has the cases the tests below cover.

(ert-deftest dirvish-refresh-listing-redraws-a-stale-preview ()
  "After gr the preview shows what the file holds now, not the cached text.
dirvish caches preview text per file and only redraws when point moves to
another file, so without the cache busting this still reads old."
  (dirvish-test-in-session '(("a.txt" . "old"))
    (let ((file (expand-file-name "a.txt" directory)))
      (dired-goto-file file)
      ;; what point landing on the file does interactively
      (dirvish--preview-update session file)
      (with-temp-file file (insert "new"))
      (dirvish-refresh-listing)
      (should (equal (dirvish-test-preview-text session) "new")))))

(ert-deftest dirvish-revisit-rereads-the-listing ()
  "Coming back to a directory lists a file that was added while away.
h, l and dired-jump all reach the listing through dired-noselect, where
dirvish hands back its existing buffer. This also fails if a dirvish
update stops running dirvish-find-entry-hook on revisits."
  (dirvish-test-in-session '()
    (let ((added (expand-file-name "added-while-away.txt" directory)))
      (with-temp-file added (insert "x"))
      (with-current-buffer (dired-noselect directory)
        (should (dired-goto-file added))))))

(ert-deftest dirvish-revisit-keeps-unfinished-wdired-edits ()
  "A revisit does not re-read a listing with pending wdired renames.
dired-jump or find-file on the directory hands the wdired buffer out
again, and re-reading it would drop the typed name."
  (dirvish-test-in-session '(("a.txt" . "a"))
    (let ((listing (current-buffer)))
      (wdired-change-to-wdired-mode)
      (unwind-protect
          (progn
            (goto-char (point-min))
            (search-forward "a.txt")
            (replace-match "renamed.txt" t t)
            (with-temp-buffer (dired-noselect directory))
            (with-current-buffer listing
              (should (buffer-modified-p))
              (goto-char (point-min))
              (should (search-forward "renamed.txt" nil t))))
        (with-current-buffer listing
          (wdired-abort-changes))))))

(ert-deftest dirvish-semicolon-plus-creates-a-directory ()
  "; + in a listing creates a directory, as ranger.el's ; prefix did."
  (dirvish-test-in-session '()
    (cl-letf (((symbol-function 'read-file-name)
               (lambda (&rest _) (expand-file-name "made-by-keys" directory))))
      (execute-kbd-macro (kbd "; +")))
    (should (file-directory-p (expand-file-name "made-by-keys" directory)))))

(provide 'emacs-test)
;;; emacs-test.el ends here
