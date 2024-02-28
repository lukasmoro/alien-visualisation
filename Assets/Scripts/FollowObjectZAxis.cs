using UnityEngine;

public class FollowObjectZAxis : MonoBehaviour
{
    public GameObject targetObject; 
    public float zDistance = 10.0f; 

    private Vector3 offset; 

    void Start()
    {
        if (targetObject != null)
        {
            offset = new Vector3(transform.position.x, transform.position.y, targetObject.transform.position.z - zDistance);
        }
        else
        {
            Debug.LogError("Target object not assigned. Please assign a target object to follow.");
        }
    }

    void Update()
    {
        if (targetObject != null)
        {
            transform.position = new Vector3(transform.position.x, transform.position.y, targetObject.transform.position.z + offset.z);
        }
    }
}
