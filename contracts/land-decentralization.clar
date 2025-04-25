;; Agricultural Land Decentralization
;; Decentralized platform for agricultural land parcel registration and management

;; Global Registry Counter
(define-data-var parcels-registered uint u0)

;; ===== Core Data Structures =====

;; Land Parcel Registry Main Database
(define-map farm-parcels
  { parcel-id: uint }
  {
    parcel-title: (string-ascii 64),
    farmer-id: principal,
    parcel-area: uint,
    registration-block: uint,
    soil-description: (string-ascii 128),
    crop-types: (list 10 (string-ascii 32))
  }
)

;; Land Parcel Access Rights Registry
(define-map parcel-permissions
  { parcel-id: uint, viewer: principal }
  { can-view: bool }
)

;; Response Status Codes
(define-constant parcel-not-found-error (err u401))
(define-constant parcel-already-registered-error (err u402))
(define-constant title-format-error (err u403))
(define-constant acreage-limit-error (err u404))
(define-constant unauthorized-access-error (err u405))
(define-constant not-parcel-owner-error (err u406))
(define-constant admin-only-action-error (err u400))
(define-constant viewing-restriction-error (err u407))
(define-constant field-validation-error (err u408))

;; Registry Administrator
(define-constant registry-admin tx-sender)


;; ===== Registry Management Functions =====

;; Creates a new land parcel entry with complete details

(define-public (register-farm-parcel 
  (title (string-ascii 64)) 
  (area uint) 
  (soil-info (string-ascii 128)) 
  (crops (list 10 (string-ascii 32)))
)
  (let
    (
      (new-parcel-id (+ (var-get parcels-registered) u1))
    )
    ;; Input validation
    (asserts! (> (len title) u0) title-format-error)
    (asserts! (< (len title) u65) title-format-error)
    (asserts! (> area u0) acreage-limit-error)
    (asserts! (< area u1000000000) acreage-limit-error)
    (asserts! (> (len soil-info) u0) title-format-error)
    (asserts! (< (len soil-info) u129) title-format-error)
    (asserts! (validate-crop-list crops) field-validation-error)

    ;; Create parcel record
    (map-insert farm-parcels
      { parcel-id: new-parcel-id }
      {
        parcel-title: title,
        farmer-id: tx-sender,
        parcel-area: area,
        registration-block: block-height,
        soil-description: soil-info,
        crop-types: crops
      }
    )

    ;; Grant owner permission
    (map-insert parcel-permissions
      { parcel-id: new-parcel-id, viewer: tx-sender }
      { can-view: true }
    )

    ;; Update global counter
    (var-set parcels-registered new-parcel-id)
    (ok new-parcel-id)
  )
)

;; Add new crops to existing parcel
(define-public (add-seasonal-crops (parcel-id uint) (new-crops (list 10 (string-ascii 32))))
  (let
    (
      (parcel-data (unwrap! (map-get? farm-parcels { parcel-id: parcel-id }) parcel-not-found-error))
      (existing-crops (get crop-types parcel-data))
      (combined-crops (unwrap! (as-max-len? (concat existing-crops new-crops) u10) field-validation-error))
    )
    ;; Verification checks
    (asserts! (parcel-registered parcel-id) parcel-not-found-error)
    (asserts! (is-eq (get farmer-id parcel-data) tx-sender) not-parcel-owner-error)

    ;; Validate crop format
    (asserts! (validate-crop-list new-crops) field-validation-error)

    ;; Update parcel with combined crops
    (map-set farm-parcels
      { parcel-id: parcel-id }
      (merge parcel-data { crop-types: combined-crops })
    )
    (ok combined-crops)
  )
)

;; ===== Utility Functions =====

;; Checks if parcel exists in registry
(define-private (parcel-registered (parcel-id uint))
  (is-some (map-get? farm-parcels { parcel-id: parcel-id }))
)

;; Verifies if caller is the rightful owner of a parcel
(define-private (is-parcel-owner (parcel-id uint) (farmer principal))
  (match (map-get? farm-parcels { parcel-id: parcel-id })
    parcel-data (is-eq (get farmer-id parcel-data) farmer)
    false
  )
)

;; Gets the registered size of a parcel
(define-private (get-parcel-area (parcel-id uint))
  (default-to u0
    (get parcel-area
      (map-get? farm-parcels { parcel-id: parcel-id })
    )
  )
)

;; Validates crop type format
(define-private (is-valid-crop (crop-name (string-ascii 32)))
  (and
    (> (len crop-name) u0)
    (< (len crop-name) u33)
  )
)

;; Verifies entire list of crop types
(define-private (validate-crop-list (crops (list 10 (string-ascii 32))))
  (and
    (> (len crops) u0)
    (<= (len crops) u10)
    (is-eq (len (filter is-valid-crop crops)) (len crops))
  )
)

;; Implement quarantine restriction on parcel
(define-public (quarantine-farm-parcel (parcel-id uint))
  (let
    (
      (parcel-data (unwrap! (map-get? farm-parcels { parcel-id: parcel-id }) parcel-not-found-error))
      (quarantine-tag "QUARANTINE-ALERT")
      (current-crops (get crop-types parcel-data))
    )
    ;; Verify authority
    (asserts! (parcel-registered parcel-id) parcel-not-found-error)
    (asserts! 
      (or 
        (is-eq tx-sender registry-admin)
        (is-eq (get farmer-id parcel-data) tx-sender)
      ) 
      admin-only-action-error
    )

    (ok true)
  )
)

;; Update existing parcel information
(define-public (update-parcel-details 
  (parcel-id uint) 
  (new-title (string-ascii 64)) 
  (new-area uint) 
  (new-soil-info (string-ascii 128)) 
  (new-crops (list 10 (string-ascii 32)))
)
  (let
    (
      (parcel-data (unwrap! (map-get? farm-parcels { parcel-id: parcel-id }) parcel-not-found-error))
    )
    ;; Validate ownership and input
    (asserts! (parcel-registered parcel-id) parcel-not-found-error)
    (asserts! (is-eq (get farmer-id parcel-data) tx-sender) not-parcel-owner-error)
    (asserts! (> (len new-title) u0) title-format-error)
    (asserts! (< (len new-title) u65) title-format-error)
    (asserts! (> new-area u0) acreage-limit-error)
    (asserts! (< new-area u1000000000) acreage-limit-error)
    (asserts! (> (len new-soil-info) u0) title-format-error)
    (asserts! (< (len new-soil-info) u129) title-format-error)
    (asserts! (validate-crop-list new-crops) field-validation-error)

    ;; Update parcel details
    (map-set farm-parcels
      { parcel-id: parcel-id }
      (merge parcel-data { 
        parcel-title: new-title, 
        parcel-area: new-area, 
        soil-description: new-soil-info, 
        crop-types: new-crops 
      })
    )
    (ok true)
  )
)

;; Check parcel ownership and history
(define-public (verify-parcel-ownership (parcel-id uint) (expected-farmer principal))
  (let
    (
      (parcel-data (unwrap! (map-get? farm-parcels { parcel-id: parcel-id }) parcel-not-found-error))
      (actual-owner (get farmer-id parcel-data))
      (registration-height (get registration-block parcel-data))
      (has-view-permission (default-to 
        false 
        (get can-view 
          (map-get? parcel-permissions { parcel-id: parcel-id, viewer: tx-sender })
        )
      ))
    )
    ;; Check access rights
    (asserts! (parcel-registered parcel-id) parcel-not-found-error)
    (asserts! 
      (or 
        (is-eq tx-sender actual-owner)
        has-view-permission
        (is-eq tx-sender registry-admin)
      ) 
      unauthorized-access-error
    )

    ;; Verify expected ownership
    (if (is-eq actual-owner expected-farmer)
      ;; Return verification results
      (ok {
        verified: true,
        current-block: block-height,
        ownership-duration: (- block-height registration-height),
        ownership-match: true
      })
      ;; Return mismatch
      (ok {
        verified: false,
        current-block: block-height,
        ownership-duration: (- block-height registration-height),
        ownership-match: false
      })
    )
  )
)

;; Remove parcel from registry
(define-public (deregister-farm-parcel (parcel-id uint))
  (let
    (
      (parcel-data (unwrap! (map-get? farm-parcels { parcel-id: parcel-id }) parcel-not-found-error))
    )
    ;; Verify ownership
    (asserts! (parcel-registered parcel-id) parcel-not-found-error)
    (asserts! (is-eq (get farmer-id parcel-data) tx-sender) not-parcel-owner-error)

    ;; Remove parcel record
    (map-delete farm-parcels { parcel-id: parcel-id })
    (ok true)
  )
)

;; Transfer parcel ownership to another farmer
(define-public (transfer-parcel-ownership (parcel-id uint) (new-farmer principal))
  (let
    (
      (parcel-data (unwrap! (map-get? farm-parcels { parcel-id: parcel-id }) parcel-not-found-error))
    )
    ;; Verify current ownership
    (asserts! (parcel-registered parcel-id) parcel-not-found-error)
    (asserts! (is-eq (get farmer-id parcel-data) tx-sender) not-parcel-owner-error)

    ;; Update parcel ownership
    (map-set farm-parcels
      { parcel-id: parcel-id }
      (merge parcel-data { farmer-id: new-farmer })
    )
    (ok true)
  )
)

;; Remove viewing permission for a specific viewer
(define-public (remove-parcel-viewer (parcel-id uint) (viewer principal))
  (let
    (
      (parcel-data (unwrap! (map-get? farm-parcels { parcel-id: parcel-id }) parcel-not-found-error))
    )
    ;; Verify parcel exists and caller is owner
    (asserts! (parcel-registered parcel-id) parcel-not-found-error)
    (asserts! (is-eq (get farmer-id parcel-data) tx-sender) not-parcel-owner-error)
    (asserts! (not (is-eq viewer tx-sender)) admin-only-action-error)

    ;; Remove viewer permission
    (map-delete parcel-permissions { parcel-id: parcel-id, viewer: viewer })
    (ok true)
  )
)

;; Grant viewing permission to a specific viewer
(define-public (add-parcel-viewer (parcel-id uint) (viewer principal))
  (let
    (
      (parcel-data (unwrap! (map-get? farm-parcels { parcel-id: parcel-id }) parcel-not-found-error))
    )
    ;; Verify parcel exists and caller is owner
    (asserts! (parcel-registered parcel-id) parcel-not-found-error)
    (asserts! (is-eq (get farmer-id parcel-data) tx-sender) not-parcel-owner-error)
    (asserts! (not (is-eq viewer tx-sender)) admin-only-action-error)

    ;; Grant viewer permission
    (map-set parcel-permissions
      { parcel-id: parcel-id, viewer: viewer }
      { can-view: true }
    )
    (ok true)
  )
)

;; Check if parcel is under quarantine
(define-public (check-parcel-status (parcel-id uint))
  (let
    (
      (parcel-data (unwrap! (map-get? farm-parcels { parcel-id: parcel-id }) parcel-not-found-error))
      (has-view-permission (default-to 
        false 
        (get can-view 
          (map-get? parcel-permissions { parcel-id: parcel-id, viewer: tx-sender })
        )
      ))
    )
    ;; Validate access permissions
    (asserts! (parcel-registered parcel-id) parcel-not-found-error)
    (asserts! 
      (or 
        (is-eq tx-sender (get farmer-id parcel-data))
        has-view-permission
        (is-eq tx-sender registry-admin)
      ) 
      unauthorized-access-error
    )

    ;; Return parcel status information
    (ok {
      active: true,
      area: (get parcel-area parcel-data),
      title: (get parcel-title parcel-data),
      registration-age: (- block-height (get registration-block parcel-data))
    })
  )
)

;; Calculate total registered land area for a farmer
(define-public (calculate-farmer-holdings (farmer-address principal))
  (begin
    ;; This would require a more complex implementation in a real system
    ;; For now we just return a placeholder
    (ok u0)
  )
)

;; Generate comprehensive parcel report 
(define-public (generate-parcel-report (parcel-id uint))
  (let
    (
      (parcel-data (unwrap! (map-get? farm-parcels { parcel-id: parcel-id }) parcel-not-found-error))
      (has-view-permission (default-to 
        false 
        (get can-view 
          (map-get? parcel-permissions { parcel-id: parcel-id, viewer: tx-sender })
        )
      ))
    )
    ;; Check permissions
    (asserts! (parcel-registered parcel-id) parcel-not-found-error)
    (asserts! 
      (or 
        (is-eq tx-sender (get farmer-id parcel-data))
        has-view-permission
        (is-eq tx-sender registry-admin)
      ) 
      unauthorized-access-error
    )

    ;; Return comprehensive report
    (ok {
      title: (get parcel-title parcel-data),
      owner: (get farmer-id parcel-data),
      area: (get parcel-area parcel-data),
      registration-date: (get registration-block parcel-data),
      soil-type: (get soil-description parcel-data),
      current-crops: (get crop-types parcel-data)
    })
  )
)



