using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SimpleMove : MonoBehaviour
{

    [SerializeField] float speed;
    [SerializeField] Vector3 offset;
    Vector3 basePos;

    private void Start()
    {
        basePos = transform.position;
    }

    // Update is called once per frame
    void Update()
    {
        transform.position = basePos + (offset * Mathf.Sin(Time.time * speed));
    }
}
