(define a 10)


(define (inc x)
  (+ 1 x))


(define (compose f g)
  (lambda (x) (f (g x))))

(define (flip func)
  (lambda (x y) (func y x)))

(define (second list)
  (first (rest list)))

(define (last list)
  (first (reverse list)))

(define (list . args)
  args)

(define (pair a b)
 '(~a ~b))

(define (first-two list)
  (pair (first list) (second list)))

(define (empty? list)
  (= list '()))

(define (pairs list)
  (define (iter acc remainder)
    (if (empty? remainder)
      (reverse acc)
      (iter (cons (first-two remainder) acc)
            (rest (rest remainder)))))
  (iter () list))


(define (reduce func acc list)
  (if (empty? list)
    acc
    (reduce func (func acc (first list)) (rest list))))

(define (mapping func)
  (lambda (acc x)
    (cons (func x) acc)))

(define (map func list)
  (reduce (mapping func) '() list))

(define (list* . items)
  (reduce (flip cons)
          (first (reverse items)) 
          (rest (reverse items))))

(define-syntax (unless test then else)
  '(if (= ~test false)
     ~then
     ~else))

(define-syntax (when test then)
  '(if ~test
     ~then
     'nil))



(define (binding-vars bindings)
  (map first bindings))

(define (binding-vals bindings)
  (map second bindings))




(define (let bindings . body)
  (map first bindings))


(define (do . forms)
  (last forms))

(define (wrap-if acc clause)
  '(if ~(first clause)
     ~(second clause)
     ~acc))

(define-syntax (cond . clauses)
  (reduce wrap-if 'nil (reverse (pairs clauses))))

(define-syntax (trace form)
  '(let (result ~form)
      (print "~form => ~result")
      result))


(define (dbg-test x)
  (debug))

