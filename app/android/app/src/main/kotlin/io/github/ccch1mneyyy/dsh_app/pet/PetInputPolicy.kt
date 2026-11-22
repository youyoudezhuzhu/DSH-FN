package io.github.ccch1mneyyy.dsh_app.pet

/**
 * Input facts are supplied by Android; the policy stays testable without pretending to inject a
 * real touch.
 *
 * A bubble's answer key must not be a way for something else to answer: no touch before [armedAt]
 * (the bubble may pop up under a finger) and none through another app's window ([obscured]). The
 * app no longer drives the screen itself (phone control is gone), so there is no in-flight
 * injection left to refuse.
 */
internal object PetInputPolicy {
    fun allows(now: Long, armedAt: Long, live: Boolean, obscured: Boolean): Boolean =
        live && now >= armedAt && !obscured
}
