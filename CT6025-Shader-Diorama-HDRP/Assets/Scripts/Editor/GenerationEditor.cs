using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
[CustomEditor(typeof(GenerationSettings))]
public class GenerationEditor : Editor
{
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
        if (GUILayout.Button("Run"))
        {
            Run();
        }

    }

    public static void Run(GenerationSettings g)
    {
        MeshFilter mf = Manager.mo.GetComponent<MeshFilter>();
        if (mf == null) return;
        mf.sharedMesh = ComputeBaker.Run(g);
    }

    public void Run()
    {
        MeshFilter mf = Manager.mo.GetComponent<MeshFilter>();
        if (mf == null) return;
        if (target is not GenerationSettings g) return;
        mf.sharedMesh = ComputeBaker.Run(g);
    }
}
