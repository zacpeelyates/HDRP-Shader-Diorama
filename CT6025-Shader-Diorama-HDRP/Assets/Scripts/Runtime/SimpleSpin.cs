using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SimpleSpin : MonoBehaviour
{
    [SerializeField] float _Speed;
   void Update()
   {
        transform.Rotate(0, _Speed * Time.deltaTime, 0, Space.Self);
   }
}
