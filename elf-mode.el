;;; elf-mode.el --- Show symbols in binaries -*- lexical-binding: t -*-

;; Copyright (C) 2024 Guilherme Thomazi Bonicontro

;; Author: Guilherme Thomazi Bonicontro <thomazi@linux.com>
;; URL: https://github.com/guitmz/elf-mode
;; Version: 0.1.0
;; Package-Requires: ((emacs "24.3"))
;; Keywords: utilities

;; This file is NOT part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Toggle `elf-mode' to show the symbols that the binary uses instead
;; of the actual binary contents.
;;
;; Use `elf-setup-default' to make `elf-mode' get called
;; automatically.

;;; Code:

(defvar-local elf-mode nil)

(defun elf-setup-default ()
  "Make `elf-mode' get called automatically for binaries."
  (add-to-list 'magic-mode-alist (cons "ELF" 'elf-mode)))

(defvar elf-mode-command "readelf --syms -W %s"
  "The shell command to use for `elf-mode'.")

;;;###autoload
(defun elf-mode ()
  (interactive)
  (let ((inhibit-read-only t))
    (if elf-mode
        (progn
          (erase-buffer)
          (insert-file-contents (buffer-file-name))
          (setq elf-mode nil))
      (setq elf-mode t)
      (erase-buffer)
      (insert (shell-command-to-string
               (format elf-mode-command (buffer-file-name)))))
    (set-buffer-modified-p nil)
    (read-only-mode 1)))

(defun elf-header2222 ()
  (interactive)
  (let ((inhibit-read-only t))
    (if elf-mode
        (progn
          (erase-buffer)
          (insert-file-contents (buffer-file-name))
          (setq elf-mode nil))
      (setq elf-mode t)
      (erase-buffer)
      (insert (shell-command-to-string
               (concat elf-mode-command " -h " (buffer-file-name)))))
    (set-buffer-modified-p nil)
    (read-only-mode 1)))

(defun elf-header-hex-old ()
  (interactive)
  (with-help-window (concat "*ELF Header Hex*" (file-name-nondirectory (buffer-file-name)))
    (special-mode)
    (local-set-key (kbd "q") 'kill-buffer-and-window)
    (insert-file-contents-literally "/Users/guilhermethomazibonicontro/Desktop/carriage" nil 0 64)
    (hexlify-buffer)))

(defun elf-header-hex ()
  "Show the first 64 bytes of the current buffer's file in hexadecimal without undo warning."
  (interactive)
  (let ((file-path (buffer-file-name)))
    (if file-path
        (let ((hex-buffer-name (concat "*ELF Header Hex: "
                                       (file-name-nondirectory file-path)
                                       "*")))
          (with-current-buffer (get-buffer-create hex-buffer-name)
            (setq buffer-read-only nil)
            (erase-buffer)
            (insert-file-contents-literally file-path nil 0 64)
            (let ((buffer-undo-list t))
              (hexl-mode))
            (use-local-map (let ((map (make-sparse-keymap)))
              (define-key map (kbd "q") 'kill-buffer-and-window)
              map))
            (pop-to-buffer hex-buffer-name)))
      (error "Current buffer is not visiting a file"))))

(defun elf-hex ()
  "Show the current buffer's file in hexadecimal without undo warning."
  (interactive)
  (let ((file-path (buffer-file-name)))
    (if file-path
        (let ((hex-buffer-name (concat "*ELF Header Hex: "
                                       (file-name-nondirectory file-path)
                                       "*")))
          (with-current-buffer (get-buffer-create hex-buffer-name)
            (setq buffer-read-only nil)
            (erase-buffer)
            (insert-file-contents-literally file-path)
            (let ((buffer-undo-list t))
              (hexl-mode))
            (use-local-map (let ((map (make-sparse-keymap)))
              (define-key map (kbd "q") 'kill-buffer-and-window)
              map))
            (pop-to-buffer hex-buffer-name)))
      (error "Current buffer is not visiting a file"))))

(defun elf-header-dismissable ()
  (interactive)
  (with-help-window (concat "*ELF Header*" (file-name-nondirectory (buffer-file-name)))
    (special-mode)
    (local-set-key (kbd "q") 'kill-buffer-and-window)
    (local-set-key (kbd "h") 'hexlify-buffer)
    (if elf-mode
        (progn
          (erase-buffer)
          (insert-file-contents (buffer-file-name))
          (setq elf-mode nil))
      (setq elf-mode t)
      (erase-buffer)
      (insert (shell-command-to-string
               (concat elf-mode-command " -h " (buffer-file-name)))))))

(require 'bindat)

(defvar simple-elf-header-spec-32
  '((ident      str 16)
    (type       u16)
    (machine    u16)
    (version    u32)
    (entry      u32)
    (phoff      u32)
    (shoff      u32)
    (flags      u32)
    (ehsize     u16)
    (phentsize  u16)
    (phnum      u16)
    (shentsize  u16)
    (shnum      u16)
    (shstrndx   u16))
  "Structure spec for parsing 32-bit ELF headers.")

(defvar simple-elf-header-spec-64-original
  '((ident      str 16)
    (type       u16)
    (machine    u16)
    (version    u32)
    (entry      u64)    ;; Entry point address
    (phoff      u64)    ;; Start of program headers
    (shoff      u64)    ;; Start of section headers
    (flags      u32)
    (ehsize     u16)
    (phentsize  u16)
    (phnum      u16)
    (shentsize  u16)
    (shnum      u16)
    (shstrndx   u16))
  "Structure spec for parsing 64-bit ELF headers.")

;; (bindat-type u64r
;;      '((lower u32r)  ;; Lower 32 bits
;;        (upper u32r)) ;; Upper 32 bits
;;      ;; Lisp expression to combine the parts into a 64-bit integer
;;      (logior (lsh (bindat-get-field struct 'upper) 32)
;;              (bindat-get-field struct 'lower))
;;      ;; The combined type consumes 8 bytes
;;      8)

(defvar simple-elf-header-spec-64
  '((magic      str 4)
    (class      u8)
    (data       u8)
    (elfversion u8)
    (os         u8)
    (abiversion u8)
    (pad  vec 7)
    (type       u16r)
    (machine    u16r)
    (version    u32r)
    (entry      u64r)    ;; Entry point address
    (phoff      u64r)    ;; Start of program headers
    (shoff      u64r)    ;; Start of section headers
    (flags      u32r)
    (ehsize     u16r)
    (phentsize  u16r)
    (phnum      u16r)
    (shentsize  u16r)
    (shnum      u16r)
    (shstrndx   u16r))
  "Structure spec for parsing 64-bit ELF headers.")

(defun simple-elf-parse-header (file)
  "Parse the ELF header of FILE and display its contents for both 32-bit and 64-bit formats."
  (interactive "fSelect ELF file: ")
  (with-temp-buffer
    (set-buffer-multibyte nil)
    ;; Read the first 16 bytes for initial identification
    (insert-file-contents-literally file nil 0 16)
    (let* ((ident (buffer-string))
           (class (aref ident 4))) ;; Get the EI_CLASS byte
      (erase-buffer)
      ;; Decide on spec based on EI_CLASS and read appropriate header size
      (let ((header-spec (cond ((= class 1) ;; ELFCLASS32
                                (insert-file-contents-literally file nil 0 52)
                                simple-elf-header-spec-32)
                               ((= class 2) ;; ELFCLASS64
                                (insert-file-contents-literally file nil 0 64)
                                simple-elf-header-spec-64)
                               (t (error "Unknown ELF class: %d" class)))))
        ;; Parse based on determined spec
        (let* ((data (buffer-string))
               (elf-header (bindat-unpack header-spec data)))
          (message "Parsed ELF Header: %S" elf-header))))))

(provide 'elf-mode)
;;; elf-mode.el ends here
