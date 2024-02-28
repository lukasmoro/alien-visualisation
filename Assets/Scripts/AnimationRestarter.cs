using UnityEngine;

public class AnimationRestarter : MonoBehaviour
{
    private Animator anim;
    private int defaultAnimationHash;

    void Start()
    {
        anim = GetComponentInChildren<Animator>();

        if (anim == null)
        {
            Debug.LogError("Animator component not found on the GameObject or its children.");
            return;
        }
        var currentAnimatorStateInfo = anim.GetCurrentAnimatorStateInfo(0);
        defaultAnimationHash = currentAnimatorStateInfo.shortNameHash;
    }

    void Update()
    {
        if (anim == null) return;
        AnimatorStateInfo stateInfo = anim.GetCurrentAnimatorStateInfo(0);

        if (stateInfo.shortNameHash == defaultAnimationHash && stateInfo.normalizedTime >= 1f)
        {
            RestartAnimation();
        }
    }

    void RestartAnimation()
    {
        anim.Play(defaultAnimationHash, -1, 0f);
        anim.Update(0f);
    }
}
