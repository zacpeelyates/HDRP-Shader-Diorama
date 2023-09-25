using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LODController : MonoBehaviour
{

    Material mat;
    int value;
    int ID;
    [SerializeField] int referenceDistance = 10;
    Camera c;
    // Start is called before the first frame update
    void Start()
    {
        mat = GetComponent<MeshRenderer>().sharedMaterial;
        ID = Shader.PropertyToID("_LODScalar");
        c = Camera.main;
    }

    // Update is called once per frame
    void Update()
    {
        int v = 1 + (int)Vector3.Distance(c.transform.position, gameObject.transform.position) / referenceDistance;
        v = Mathf.Clamp(v,1,8);
        if(value != v)
        {
            value = v;
            mat.SetInt(ID,value);
            Debug.Log(v);
        }
    }

    void OnApplicationQuit()
    {
        mat.SetInt(ID,1);
    }
}
