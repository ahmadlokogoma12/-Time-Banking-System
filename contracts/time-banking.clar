;; Time Banking System Smart Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-insufficient-balance (err u103))

;; Data Variables
(define-data-var user-id-nonce uint u0)
(define-data-var service-id-nonce uint u0)
(define-data-var project-id-nonce uint u0)

;; Maps
(define-map users
  { user-id: uint }
  {
    address: principal,
    time-balance: uint,
    reputation: uint,
    skills: (list 10 (string-ascii 20))
  }
)

(define-map services
  { service-id: uint }
  {
    provider: uint,
    seeker: uint,
    duration: uint,
    description: (string-utf8 200),
    status: (string-ascii 20)
  }
)

(define-map projects
  { project-id: uint }
  {
    name: (string-ascii 50),
    description: (string-utf8 500),
    required-skills: (list 5 (string-ascii 20)),
    total-hours: uint,
    status: (string-ascii 20)
  }
)

(define-map project-participants
  { project-id: uint, user-id: uint }
  { hours-contributed: uint }
)

;; Private Functions
(define-private (get-user-id (address principal))
  (fold get-user-id-iter (map-keys users) u0)
)

(define-private (get-user-id-iter (user-id uint) (result uint))
  (let ((user (unwrap! (map-get? users { user-id: user-id }) result)))
    (if (is-eq (get address user) address)
      user-id
      result
    )
  )
)

;; Public Functions

;; User Registration
(define-public (register-user (skills (list 10 (string-ascii 20))))
  (let
    (
      (new-user-id (+ (var-get user-id-nonce) u1))
    )
    (asserts! (is-none (get-user-id tx-sender)) err-already-exists)
    (map-set users
      { user-id: new-user-id }
      {
        address: tx-sender,
        time-balance: u0,
        reputation: u100,  ;; Initial reputation
        skills: skills
      }
    )
    (var-set user-id-nonce new-user-id)
    (ok new-user-id)
  )
)

;; Offer Service
(define-public (offer-service (description (string-utf8 200)) (duration uint))
  (let
    (
      (provider-id (get-user-id tx-sender))
      (new-service-id (+ (var-get service-id-nonce) u1))
    )
    (asserts! (> provider-id u0) err-not-found)
    (map-set services
      { service-id: new-service-id }
      {
        provider: provider-id,
        seeker: u0,
        duration: duration,
        description: description,
        status: "offered"
      }
    )
    (var-set service-id-nonce new-service-id)
    (ok new-service-id)
  )
)

;; Accept Service
(define-public (accept-service (service-id uint))
  (let
    (
      (seeker-id (get-user-id tx-sender))
      (service (unwrap! (map-get? services { service-id: service-id }) err-not-found))
    )
    (asserts! (is-eq (get status service) "offered") err-already-exists)
    (asserts! (> seeker-id u0) err-not-found)
    (map-set services
      { service-id: service-id }
      (merge service {
        seeker: seeker-id,
        status: "accepted"
      })
    )
    (ok true)
  )
)

;; Complete Service
(define-public (complete-service (service-id uint))
  (let
    (
      (service (unwrap! (map-get? services { service-id: service-id }) err-not-found))
      (provider (unwrap! (map-get? users { user-id: (get provider service) }) err-not-found))
      (seeker (unwrap! (map-get? users { user-id: (get seeker service) }) err-not-found))
    )
    (asserts! (is-eq (get status service) "accepted") err-not-found)
    (asserts! (or (is-eq tx-sender (get address provider)) (is-eq tx-sender (get address seeker))) err-owner-only)

    ;; Transfer time credits
    (map-set users
      { user-id: (get provider service) }
      (merge provider { time-balance: (+ (get time-balance provider) (get duration service)) })
    )
    (map-set users
      { user-id: (get seeker service) }
      (merge seeker { time-balance: (- (get time-balance seeker) (get duration service)) })
    )

    ;; Update service status
    (map-set services
      { service-id: service-id }
      (merge service { status: "completed" })
    )

    (ok true)
  )
)

;; Rate Service
(define-public (rate-service (service-id uint) (rating uint))
  (let
    (
      (service (unwrap! (map-get? services { service-id: service-id }) err-not-found))
      (rater-id (get-user-id tx-sender))
      (rated-id (if (is-eq rater-id (get provider service)) (get seeker service) (get provider service)))
      (rated-user (unwrap! (map-get? users { user-id: rated-id }) err-not-found))
    )
    (asserts! (is-eq (get status service) "completed") err-not-found)
    (asserts! (or (is-eq rater-id (get provider service)) (is-eq rater-id (get seeker service))) err-owner-only)
    (asserts! (and (>= rating u1) (<= rating u5)) err-owner-only)

    ;; Update user reputation
    (map-set users
      { user-id: rated-id }
      (merge rated-user {
        reputation: (/ (+ (* (get reputation rated-user) u9) (* rating u20)) u10)
      })
    )

    (ok true)
  )
)

;; Create Community Project
(define-public (create-project (name (string-ascii 50)) (description (string-utf8 500)) (required-skills (list 5 (string-ascii 20))) (total-hours uint))
  (let
    (
      (new-project-id (+ (var-get project-id-nonce) u1))
    )
    (map-set projects
      { project-id: new-project-id }
      {
        name: name,
        description: description,
        required-skills: required-skills,
        total-hours: total-hours,
        status: "open"
      }
    )
    (var-set project-id-nonce new-project-id)
    (ok new-project-id)
  )
)

;; Contribute to Project
(define-public (contribute-to-project (project-id uint) (hours uint))
  (let
    (
      (user-id (get-user-id tx-sender))
      (user (unwrap! (map-get? users { user-id: user-id }) err-not-found))
      (project (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
      (current-contribution (default-to { hours-contributed: u0 } (map-get? project-participants { project-id: project-id, user-id: user-id })))
    )
    (asserts! (is-eq (get status project) "open") err-not-found)
    (asserts! (>= (get time-balance user) hours) err-insufficient-balance)

    ;; Update user's time balance
    (map-set users
      { user-id: user-id }
      (merge user { time-balance: (- (get time-balance user) hours) })
    )

    ;; Update project contribution
    (map-set project-participants
      { project-id: project-id, user-id: user-id }
      { hours-contributed: (+ (get hours-contributed current-contribution) hours) }
    )

    ;; Check if project is completed
    (if (>= (+ (get hours-contributed current-contribution) hours) (get total-hours project))
      (map-set projects
        { project-id: project-id }
        (merge project { status: "completed" })
      )
      true
    )

    (ok true)
  )
)

;; Read-only Functions

(define-read-only (get-user-details (user-id uint))
  (map-get? users { user-id: user-id })
)

(define-read-only (get-service-details (service-id uint))
  (map-get? services { service-id: service-id })
)

(define-read-only (get-project-details (project-id uint))
  (map-get? projects { project-id: project-id })
)

(define-read-only (get-project-contribution (project-id uint) (user-id uint))
  (map-get? project-participants { project-id: project-id, user-id: user-id })
)

