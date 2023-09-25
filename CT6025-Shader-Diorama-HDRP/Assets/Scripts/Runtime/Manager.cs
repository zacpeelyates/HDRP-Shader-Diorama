using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class Manager : MonoBehaviour
{
    [SerializeField] List<GameObject> hide;
    [SerializeField] Light MainLight;
    [SerializeField] private GameObject meshObject;

    public static GameObject mo;
    private void OnValidate()
    {
        mo = meshObject;
        SetupLightingReference();
    }

    void  Awake()
    {
       mo = meshObject;
      //Show Hidden Objects
      foreach(GameObject g in hide)
      {
        {
           if(g!=null) g.SetActive(Application.isPlaying);
        }
      }
    }

    Vector3 dirCache;
    Color colCache;

    private void Update()
    {

        SetupLightingReference();

    }

    void SetupLightingReference()
    {
        Color c;
        Vector3 dir;
        if (MainLight != null)
        {
            c = MainLight.color;
            dir = MainLight.transform.forward;
        }
        else
        {
            c = Color.grey;
            dir = new Vector3(2, 1, 0);
        }

        Debug.Log(c);
        Debug.Log(dir);

        if (c != colCache || dir != dirCache)
        {
            Shader.SetGlobalColor("_MainLightColor", c);
            Shader.SetGlobalVector("_MainLightDirection", dir);
        }
    }

    void OnDestroy()
   {
      //Hide Hidden Objects
     foreach(GameObject g in hide)
      {
        {
            if(g!=null) g.SetActive(false);
        }
      }
   }



 
}
