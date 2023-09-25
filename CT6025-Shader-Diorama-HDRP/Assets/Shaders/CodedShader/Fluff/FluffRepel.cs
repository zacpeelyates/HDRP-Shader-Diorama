using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[RequireComponent(typeof(MeshRenderer))]
public class FluffRepel : MonoBehaviour
{

    Material mat;
    Vector4 buffer;
    int ID;
    public GameObject o;
    // Start is called before the first frame update
    void Start()
    {
        if(o == null) o = Camera.main.gameObject;
        mat = GetComponent<MeshRenderer>().sharedMaterial;
        ID = Shader.PropertyToID("_FluffRepelPosition");
        buffer = mat.GetVector(ID);
    }

    Vector4 v;
    Vector4 prev;
    // Update is called once per frame
    void Update()
    {
        v = o.transform.position;
        if (v!=prev)
        {
            mat.SetVector(ID, v);
            prev = v;
        }
    }

    private void OnApplicationQuit()
    {
        mat.SetVector(ID, buffer);
    }
}
