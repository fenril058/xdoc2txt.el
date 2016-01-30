;;; xdoc2txt.el --- binary converter                 -*- lexical-binding: t; -*-

;; Copyright (C) 2016  ril

;; Author: ril
;; Created: 2016-01-30 20:27:29
;; Last Modified: 2016-01-30 23:38:46
;; Version: 0.1
;; Keywords: Windows, data
;; URL: https://github.com/fenril058/xdoc2txt

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This program is a interface of the xdoc2txt for Emacs.  It's only
;; compatible with emacs 24.4 and later, because of `nadvice.el'.

;; This file is originated from
;;  <http://www.bookshelf.jp/soft/meadow_23.html#SEC238>

;; xdoc2txt is a text converter which extract text from binary file
;; such as PDF, WORD, EXCEL, 一太郎 etc. Its binary file and more
;; infomation can be obtained from
;; <http://ebstudio.info/home/xdoc2txt.html>

;;; Code
(require 'cl-lib)

(defgroup xdoc2txt nil
  "xdoc2txt interface for Emacs"
  :group 'emacs)

(defcustom xdoc2txt-binary-use-xdoc2txt (executable-find "xdoc2txt.exe")
  "If non-nil，use xdoc2txt when the binary file whose extensions
is in `xdoc2txt-extensions'．"
  :type 'boolean
  :group 'xdoc2txt)

(defcustom xdoc2txt-encoding 'utf-8
  "Enconfig for xdoc2txt. You can choose utf-8, utf-16, euc-jp,
  japanese-shift-jis, and sjis"
  :type 'symbol
  :group 'xdoc2txt.el)

(defcustom xdoc2txt-extensions
  '("rtf" "doc" "xls" "ppt" "docx" "xlsx" "pptx"
    "jaw" "jtw" "jbw" "juw" "jfw" "jvw" "jtd" "jtt"
    "oas" "oa2" "oa3" "bun"
    "wj2" "wj3" "wk3" "wk4"
    "123" "wri" "pdf" "mht")
  "*List of file extensions which are handled by xdoc2txt.
They must be written in lowercase."
  :type 'list
  :group 'xdoc2txt)

(defvar xdoc2txt-encoding-option nil)

(defun xdoc2txt-select-encoding ()
  (interactive)
  (let ((code xdoc2txt-encoding))
    (setq xdoc2txt-encoding-option
          (cl-case code
            ('utf-8 " -8 ")
            ('utf-16 " -u ")
            ('euc-jp " -e ")
            ('japanese-shift-jis " -s ")
            ('sjis " -j ")
            ))))

(defun xdoc2txt-binary-file-view (file)
  "View a file with xdoc2txt"
  (interactive "f")
  (let ((dummy-buff
         (generate-new-buffer
          (concat "xdoc2txt:" (file-name-nondirectory file)))))
    (set-buffer dummy-buff)
    (let ((fn (concat
               (expand-file-name
                (make-temp-name "xdoc2")
                temporary-file-directory)
               "."
               (file-name-extension file)
               )))
      (copy-file file fn t)
      (insert
       "XDOC2TXT FILE: " (file-name-nondirectory file) "\n"
       "----------------------------------------------------\n"
       (xdoc2txt-select-encoding)
       (shell-command-to-string
        (concat "xdoc2txt" xdoc2txt-encoding-option fn)
        ))
      (goto-char (point-min))
      (while (re-search-forward "\r" nil t)
        (delete-region (match-beginning 0)
                       (match-end 0)))
      (goto-char (point-min))
      (while (re-search-forward
              "\\([\n ]+\\)\n[ ]*\n" nil t)
        (delete-region (match-beginning 1)
                       (match-end 1)))
      (delete-file fn)
      )
    (setq buffer-read-only t)
    (set-window-buffer (selected-window) dummy-buff))
  (goto-char (point-min))
  (view-mode t))

(defun xdoc2txt-advice-find-file (orig-func file &rest args)
  (if (and
       xdoc2txt-binary-use-xdoc2txt
       (member (file-name-extension file) xdoc2txt-extensions)
       (y-or-n-p
         "use xdoc2txt to show the binary data?"))
      (xdoc2txt-binary-file-view file)
    (apply orig-func file args))
  'around)
(advice-add 'find-file :around 'xdoc2txt-advice-find-file)

(defun xdoc2txt-remove-advice-find-file ()
  (interactive)
  (advice-remove 'find-file 'xdoc2txt-advice-find-file))

;; (defadvice find-file (around xdoc2txt-find-file (file &optional wildcards))
;;   (if (and
;;        xdoc2txt-binary-use-xdoc2txt
;;        (member (file-name-extension file) xdoc2txt-extensions)
;;        (y-or-n-p
;;         "use xdoc2txt to show the binary data?"))
;;       (xdoc2txt-binary-file-view file)
;;     ad-do-it))
;; (ad-activate 'find-file)

(provide 'xdoc2txt)
;;; xdoc2txt.el ends here