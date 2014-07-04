;;; anaconda-mode-test.el --- anaconda-mode test suite

;;; Commentary:

;;; Code:

(require 'ert)

;;; Server.

(ert-deftest test-anaconda-mode-running ()
  "Test if anaconda_mode running successfully."
  (anaconda-mode-start-node)
  (should (anaconda-mode-running-p)))

(ert-deftest test-anaconda-mode-virtualenv ()
  "Check that anaconda_mode start with proper python executable."
  (should (string= (anaconda-mode-python)
                   (getenv "ENVPYTHON"))))

(ert-deftest test-anaconda-mode-set-port ()
  (let* ((output "anaconda_mode port 24970")
         (buffer (generate-new-buffer "cat"))
         (process (start-process "-" buffer "cat" "--help"))
         (anaconda-mode-port nil))
    (with-current-buffer buffer
      (erase-buffer)
      (insert output))
    (anaconda-mode-set-port process)
    (should (numberp anaconda-mode-port))))

(ert-deftest test-anaconda-mode-set-port-error ()
  (let* ((output "Process anaconda_mode finished")
         (buffer (generate-new-buffer "cat"))
         (process (start-process "-" buffer "cat" "--help"))
         (anaconda-mode-port nil))
    (with-current-buffer buffer
      (erase-buffer)
      (insert output))
    (should-error (anaconda-mode-set-port process))))

(ert-deftest test-anaconda-mode-clean-own-buffer ()
  (anaconda-mode-start-node)
  (let (anaconda-mode-port)
    (anaconda-mode-start-node)
    (with-current-buffer "*anaconda*"
      (should (eq 1 (length (s-lines (buffer-string))))))))

;;; Completion.

(ert-deftest test-anaconda-mode-complete ()
  "Test completion at point."
  (load-fixture "simple.py" "\
def test1(a, b):
    '''First test function.'''
    pass

def test2(c):
    '''Second test function.'''
    pass
test_|_")
  (should (equal (anaconda-mode-complete-thing)
                 '("test1" "test2"))))

;;; Documentation.

(ert-deftest test-anaconda-mode-doc ()
  "Test documentation string search."
  (load-fixture "simple.py" "\
def f_|_(a, b=1):
    '''Docstring for f.'''
    pass")
  (anaconda-mode-view-doc)
  (should (equal (with-current-buffer (get-buffer "*anaconda-doc*")
                   (buffer-string))
                 "\
simple - def f
========================================
f(a, b = 1)

Docstring for f.")))

;;; ElDoc.

(ert-deftest test-anaconda-eldoc-existing ()
  (load-fixture "simple.py" "\
def fn(a, b):
    pass
fn(_|_")
  (should (equal (anaconda-eldoc-function)
                 "fn(a, b)")))

(ert-deftest test-anaconda-eldoc-invalid ()
  (load-fixture "simple.py" "invalid(_|_")
  (should-not (anaconda-eldoc-function)))

(ert-deftest test-anaconda-eldoc-ignore-errors ()
  (let ((anaconda-mode-directory (f-root))
        (anaconda-mode-port nil))
    (should-not (anaconda-eldoc-function))))

(provide 'anaconda-mode-test)

;;; anaconda-mode-test.el ends here
