\version "2.25.18"
% -*- master: tests.ly;

#(use-modules (ice-9 and-let-star))

#(define ((char-height c extent-proc) layout font)
   (let* ((fonts (assq-ref (ly:output-def-lookup layout 'property-defaults) 'fonts))
          (props `(((font-encoding . latin1)
                    (font-family . ,font)
                    (fonts . ,(cons* '(default-serif . "LilyPond Serif")
                                     '(default-sans . "LilyPond Sans Serif")
                                     '(default-mono . "LilyPond Monospace")
                                     fonts)))))
          (stencil (interpret-markup layout props c))
          (height (interval-length (extent-proc stencil Y))))
     height))

#(define x-height (char-height "x" ly:stencil-extent))
#(define x-true-height (char-height "x" stencil-true-extent))
#(define cap-height (char-height "I" ly:stencil-extent))
#(define cap-true-height (char-height "I" stencil-true-extent))

#(define (init-font-size-corrections layout-ctx)
   (let* ((layout (ly:context-output-def layout-ctx))
          (fonts-info (ly:output-def-lookup layout 'fonts-info)))
     
     (define (get-font-dimen font dimen)
       (or (assq-ref (cdr font) dimen)
           (let* ((dimen-proc (module-ref (current-module) dimen))
                  (dimen-val (dimen-proc layout (car font))))
             (set-cdr! font (acons dimen dimen-val (cdr font)))
             dimen-val)))
     
     (define (set-correction! font)
       (and-let* (((not (assq-ref (cdr font) 'size-correction)))
                  (normalize-to (assq-ref (cdr font) 'normalize-to))
                  (dimen (car normalize-to))
                  (reference (cdr normalize-to))
                  (my-size (get-font-dimen font dimen))
                  (ref-size (if (symbol? reference)
                                (get-font-dimen 
                                 (or (assq reference fonts-info)
                                     (and (set! fonts-info 
                                                (acons reference '() fonts-info))
                                          (assq reference fonts-info)))
                                 dimen)
                                reference))
                  (size-correction (magnification->font-size (/ ref-size my-size))))
           (set-cdr! font (acons 'size-correction size-correction (cdr font)))))
     
     (for-each set-correction! fonts-info)
     (ly:output-def-set-variable! layout 'fonts-info fonts-info)
   ;   (ly:message "~a" (ly:output-def-lookup layout 'fonts-info))
     ))

#(define-markup-command (normalize-size layout props arg) (markup?)
   #:properties (fontsize-markup
                 (font-family 'serif))
   (or (and-let* ((font-info (assq-ref (ly:output-def-lookup layout 'fonts-info) font-family))
                  (correction (assq-ref font-info 'size-correction)))
         (ly:message "~a ~a" correction font-family)
         (fontsize-markup layout props correction arg))
       (interpret-markup layout props arg)))

#(define-markup-command (select-optical-variant layout props arg) (markup?)
   #:properties ((font-size 0)
                 (font-family 'serif))
   (or (and-let* ((base-size (ly:output-def-lookup layout 'text-font-size))
                  (pt-size (* base-size (magstep font-size)))
                  (font-info (assq-ref (ly:output-def-lookup layout 'fonts-info) font-family))
                  (optical-sizes (assq-ref font-info 'optical-sizes))
                  (this-size (assoc pt-size optical-sizes (lambda (key alistcar)
                                                            (and (< (car alistcar) key)
                                                                 (<= key (cdr alistcar))))))
                  (optical-family (symbol-append font-family '- (cdr this-size))))
          (override-markup layout props `(font-family . ,optical-family) arg))
       (interpret-markup layout props arg)))

#(define (select-variant-and-normalize layout props arg)
   (markup #:select-optical-variant #:normalize-size arg))

#(define ((add-default-string-transformer transformer) ctx)
   (let* ((layout (ly:context-output-def ctx))
          (property-defaults (ly:output-def-lookup layout 'property-defaults))
          (string-transformers (assq-ref property-defaults 'string-transformers)))
     (ly:output-def-set-variable! layout 'property-defaults
                                  (assq-set! property-defaults 'string-transformers 
                                             (cons transformer string-transformers)))))
     
normalizeOpticalTextSizes = \with {
  \applyContext #init-font-size-corrections
  \applyContext #(add-default-string-transformer select-variant-and-normalize)
}
