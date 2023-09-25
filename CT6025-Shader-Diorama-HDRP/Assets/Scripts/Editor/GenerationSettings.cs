using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(menuName = "GenerationSettings", fileName = "New GenerationSettings")]
public class GenerationSettings : ScriptableObject
{

    private void OnValidate()
    {
        GenerationEditor.Run(this);
    }

    public ComputeShader NoiseShader;
    public ComputeShader GenShader;

    public int seed;
    public float surfaceLevel;

    public int pointsPerAxis;


    public int TotalPoints => pointsPerAxis * pointsPerAxis * pointsPerAxis;

    public int VoxelsPerAxis => pointsPerAxis - 1;

    public int TotalVoxels => VoxelsPerAxis * VoxelsPerAxis * VoxelsPerAxis;


    public int MaxTriangles => TotalVoxels * 5;

    [SerializeField] private BoundsInteralClass BoundsInternal;
    [SerializeField] private NoiseParamsInternalClass NoiseInternal;

    [System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
    public struct GenerationBounds
    {
        public float size;
        public Vector3 centre;
        public Vector3 offset;
        public float spacing;
    }

    [System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
    public struct NoiseParams
    {
        public int Octaves;
        public float Persistance;
        public float Lacunarity;

        public float Scale;
        public float Weight;
        public float WeightScale;

        public float Floor;
        public float FloorWeight;
        public float FloorOffset;
    }

    public GenerationBounds BoundsSettings
    {
        get
        {
            GenerationBounds result = new();
            result.size = BoundsInternal.size;
            result.centre = BoundsInternal.centre;
            result.offset = BoundsInternal.offset;
            result.spacing = BoundsInternal.spacing;

            return result;
        }
    }

    public NoiseParams NoiseSettings
    {
        get
        {
            NoiseParams result = new();
            result.Octaves = NoiseInternal.Octaves;
            result.Persistance = NoiseInternal.Persistance;
            result.Lacunarity = NoiseInternal.Lacunarity;
            result.Scale = NoiseInternal.Scale;
            result.Weight = NoiseInternal.Weight;
            result.WeightScale = NoiseInternal.Weight;
            result.Floor = NoiseInternal.Floor;
            result.FloorWeight = NoiseInternal.FloorWeight;
            result.FloorOffset = NoiseInternal.FloorOffset;
            return result;
        }
    }

    [System.Serializable] private class BoundsInteralClass
    {
        public float size;
        [System.NonSerialized] public Vector3 centre;
        public Vector3 offset;
        [System.NonSerialized] public float spacing;
    };


     public const int BOUNDS_STRIDE = sizeof(float) * 8;


    [System.Serializable] private class NoiseParamsInternalClass
    {
        public int   Octaves;
        public float Persistance;
        public float Lacunarity;

        public float Scale;
        public float Weight;
        public float WeightScale;

        public float Floor;
        public float FloorWeight;
        public float FloorOffset;

    };
    public const int NOISE_STRIDE = sizeof(float) * 8 + sizeof(int);



}
