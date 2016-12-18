;;; mentor-data.el --- Mentor data structures  -*- lexical-binding: t -*-

;; Copyright (C) 2016 Stefan Kangas.

;; Author: Stefan Kangas <stefankangas@gmail.com>

;; Mentor is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; Mentor is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with Mentor.  If not, see http://www.gnu.org/licenses.

;;; Commentary:

;; This library contains internal data structures used by Mentor.

;;; Code:

;;; Mentor items

(require 'cl-lib)

(cl-defstruct mentor-item
  "A structure containing an item that can be displayed
in a buffer, like a torrent, file, directory, peer etc."
  id data marked type)

(defvar mentor-items nil
  "Hash table containing all items for the current buffer.
This can be torrents, files, peers etc.  All values should be made
using `make-mentor-item'.")
(make-variable-buffer-local 'mentor-items)

(defun mentor-get-item (id)
  (gethash id mentor-items))

(defun mentor-get-item-at-point ()
  (mentor-get-item (mentor-item-id-at-point)))

(defun mentor-item-id-at-point ()
  (get-text-property (point) 'field))

;; TODO: Probably get rid of this
(defun mentor-item-get-name (torrent)
  (mentor-item-property 'name torrent))

(defun mentor-item-set-property (property value &optional item must-exist)
  "Set data PROPERTY to given VALUE of an item.

If ITEM is nil, use torrent at point.

If MUST-EXIST is non-nil, give a warning if the property does not
  already exist."
  
  (let ((it (or item
                (mentor-get-item-at-point)
                (error "There is no item here"))))
    (let ((prop (assq property (mentor-item-data it))))
      (if prop
          (setcdr prop value)
        (if must-exist
            (error "Tried updating non-existent property")
          (push (cons property value) (mentor-item-data it)))))))

;; TODO: Can we change to use assq instead of assoc?
(defun mentor-item-property (property &optional item)
  "Get PROPERTY for item at point or ITEM."
  (let ((it (or item
                (mentor-get-item-at-point)
                (error "There is no item here"))))
    (cdr (assoc property (mentor-item-data it)))))

;;; Torrent data structure

(defun mentor-torrent-create (data)
  (make-mentor-item
   :id   (cdr (assq 'local_id data))
   :type 'torrent
   :marked nil
   :data data))

(defun mentor-torrent-update (new &optional is-init)
  "Add or update a torrent using data in NEW."
  (let* ((id  (mentor-item-property 'local_id new))
         (old (mentor-get-item id)))
    (when (and (null old)
               (not is-init))
      (signal 'mentor-need-init `("No such torrent" ,id)))
    (if is-init
        (progn (setf (mentor-item-marked new) nil)
               (puthash id new mentor-items))
      (dolist (row (mentor-item-data new))
        (let* ((p (car row))
               (v (cdr row)))
          (mentor-item-set-property p v old 'must-exist))))))

(put 'mentor-need-init
     'error-conditions
     '(error mentor-error mentor-need-init))

;; Mentor file data structure

(cl-defstruct mentor-file
  "The datastructure that contains the information about torrent
files.  A mentor-file can be either a regular file or a filename
and if it is the latter it will contain a list of the files it
contain.  If it is a regular file it will contain an id which is
the integer index used by rtorrent to identify this file."
  name show marked size completed_chunks
  size_chunks priority files type id)

(provide 'mentor-data)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; mentor-data.el ends here
