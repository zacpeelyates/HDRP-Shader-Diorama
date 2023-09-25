using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class ComputeBaker
{
    const int THREAD_COUNT = 8;
    static int THREADS_PER_AXIS;
    public static Mesh test(GenerationSettings settings)
    {

        ComputeShader noise = settings.NoiseShader;
        int ID = noise.FindKernel("CSMain");

        // Noise parameters
        var prng = new System.Random(settings.seed);
        var offsets = new Vector3[settings.NoiseSettings.Octaves];
        float offsetRange = 1000;
        for (int i = 0; i < settings.NoiseSettings.Octaves; i++)
        {
            offsets[i] = new Vector3((float)prng.NextDouble() * 2 - 1, (float)prng.NextDouble() * 2 - 1, (float)prng.NextDouble() * 2 - 1) * offsetRange;
        }

        var offsetsBuffer = new ComputeBuffer(offsets.Length, sizeof(float) * 3);
        offsetsBuffer.SetData(offsets);

        var n = settings.NoiseSettings;

        noise.SetVector("centre", Vector4.zero);
        noise.SetInt("octaves", n.Octaves);
        noise.SetFloat("lacunarity", n.Lacunarity);
        noise.SetFloat("persistence", n.Persistance);
        noise.SetFloat("noiseScale", n.Scale);
        noise.SetFloat("noiseWeight", n.Weight);
        noise.SetBool("closeEdges", false);
        noise.SetBuffer(ID, "offsets", offsetsBuffer);
        noise.SetFloat("floorOffset", n.FloorOffset);
        noise.SetFloat("weightMultiplier", n.WeightScale);
        noise.SetFloat("hardFloor", n.Floor);
        noise.SetFloat("hardFloorWeight", n.FloorWeight);

        noise.SetVector("params", Vector4.one);

        ComputeBuffer points = new(settings.TotalPoints, sizeof(float) * 4, ComputeBufferType.Structured);

        noise.SetBuffer(ID, "points", points);
        noise.SetInt("numPointsPerAxis", settings.pointsPerAxis);
        noise.SetFloat("boundsSize", settings.BoundsSettings.size);
        noise.SetVector("offset", settings.BoundsSettings.offset);
        noise.SetFloat("spacing", settings.BoundsSettings.size / (settings.pointsPerAxis -1));
        noise.SetVector("worldSize", Vector3.zero);

        noise.Dispatch(ID, THREADS_PER_AXIS, THREADS_PER_AXIS, THREADS_PER_AXIS);

        Vector4[] tester = new Vector4[settings.TotalPoints];
        points.GetData(tester);



        //-------------------------------------------------------------------------------------------------------------

        ComputeShader generator = settings.GenShader;
         ID = generator.FindKernel("CSMain");
        generator.SetInt("numPointsPerAxis", settings.pointsPerAxis);
        generator.SetFloat("isoLevel", settings.surfaceLevel);

        ComputeBuffer triBuffer = new ComputeBuffer(settings.MaxTriangles, sizeof(float) * 9, ComputeBufferType.Append);

        generator.SetBuffer(ID, "points", points);
        generator.SetBuffer(ID, "triangles", triBuffer);

        generator.Dispatch(ID, THREADS_PER_AXIS, THREADS_PER_AXIS, THREADS_PER_AXIS);

        ComputeBuffer triCountBuffer = new ComputeBuffer(1, sizeof(int), ComputeBufferType.Raw);
        ComputeBuffer.CopyCount(triBuffer, triCountBuffer,0);
        int[] tricountarr = { 0 };
        triCountBuffer.GetData(tricountarr);
        int triCount = tricountarr[0];

        Tri[] tris = new Tri[triCount];
        triBuffer.GetData(tris, 0, 0, triCount);

        Vector3[] verts = new Vector3[triCount * 3];
        int[] meshTriangles = new int[triCount * 3];
        Tri prevTri = new();
        for(int i = 0; i < triCount; ++i)
        {
            Vector3 prev = Vector3.zero;
            for(int j = 0; j < 3; ++j)
            {
                int index = i * 3 + j;
                meshTriangles[index] = index;
                verts[index] = tris[i][j];

                if(j != 0)
                {
                    if(Vector3.Distance(verts[index],prev) > 30)
                    {
                        tris[i] = prevTri;
                        break;
                    }
                    else
                    {
                        prevTri = tris[i];
                    }
                }
                prev = tris[i][j];
            }

        }

        triBuffer.Release();
        points.Release();
        offsetsBuffer.Release();
        

        Mesh mesh = new();
        mesh.vertices = verts;
        mesh.triangles = meshTriangles;

        mesh.RecalculateNormals();
        mesh.RecalculateBounds();

        return mesh;

    }
    public static Mesh Run(GenerationSettings settings)
    {
        THREADS_PER_AXIS = Mathf.CeilToInt(settings.VoxelsPerAxis / THREAD_COUNT);
        return test(settings);

    }

    public struct Tri
    {
       public Vector3 a, b, c;

        public Vector3 this[int i]
        {
            get
            {
                return i switch
                {
                    0 => a,
                    1 => b,
                    _ => c
                };
            }
        }

    }


    static Mesh March(GenerationSettings settings, ComputeBuffer noise)
    {
        var s = settings.GenShader;
        int ID = s.FindKernel("CSMain");

        s.SetBuffer(ID, "_InVerts", noise);

        ComputeBuffer CBOutTris = new(settings.MaxTriangles, sizeof(float) * 9, ComputeBufferType.Append);
        s.SetBuffer(ID,"_OutTris", CBOutTris);

        s.SetFloat("_ISOLevel", settings.surfaceLevel);

        s.Dispatch(ID, THREADS_PER_AXIS, THREADS_PER_AXIS, THREADS_PER_AXIS);

        ComputeBuffer CBTriCount = new(1, sizeof(int), ComputeBufferType.IndirectArguments);
        int[] triCountArr = new int[1];
        ComputeBuffer.CopyCount(CBOutTris, CBTriCount, 0);
        CBTriCount.GetData(triCountArr);
        int triCount = triCountArr[0];

        Tri[] tris = new Tri[triCount];
        CBOutTris.GetData(tris, 0, 0, triCount);

        CBOutTris.Release();
        noise.Release();
        CBTriCount.Release();

        Vector3[] meshVerts = new Vector3[triCount * 3];
        int[] meshTris = new int[triCount * 3];

        for(int i = 0; i < triCount; ++i)
        {
            for(int j = 0; j < 3; ++j)
            {
                int index = i * 3 + j;
                meshVerts[index] = tris[i][j];
                meshTris[index] = index;
            }
        }

        Mesh mesh = new();
        mesh.vertices = meshVerts;
        mesh.triangles = meshTris;
        mesh.RecalculateNormals();
        mesh.RecalculateNormals();
        return mesh;
    
    }

    static ComputeBuffer Noise(GenerationSettings settings)
    {
        var n =  new GenerationSettings.NoiseParams[] { settings.NoiseSettings };
        var b =  new GenerationSettings.GenerationBounds[] { settings.BoundsSettings };
        var s = settings.NoiseShader;
        int ID = s.FindKernel("CSMain");


        System.Random rng = new(settings.seed);
        Vector3[] offsets = new Vector3[n[0].Octaves];
        float range = 1000;
        for(int i = 0; i < offsets.Length; ++i)
        {
            offsets[i] = new Vector3(
                (float)rng.NextDouble() * 2 - 1,
                (float)rng.NextDouble() * 2 - 1,
                (float)rng.NextDouble() * 2 - 1
            ) * range;          
        }

        b[0].spacing = b[0].size / (settings.pointsPerAxis - 1);
        b[0].centre = Vector3.zero;

        ComputeBuffer CBOffsets = new(offsets.Length, sizeof(float) * 3,ComputeBufferType.Structured);
        CBOffsets.SetData(offsets);
        s.SetBuffer(ID, "_InOffsets",CBOffsets);

        ComputeBuffer CBNoiseParams = new(1, GenerationSettings.NOISE_STRIDE, ComputeBufferType.Raw);
        CBNoiseParams.SetData(n);
        s.SetBuffer(ID, "_NoiseParamsSB", CBNoiseParams);

        ComputeBuffer CBBoundsParams = new(1, GenerationSettings.BOUNDS_STRIDE, ComputeBufferType.Raw);
        CBBoundsParams.SetData(b);
        s.SetBuffer(ID, "_BoundsSB", CBBoundsParams);

        ComputeBuffer CBOutVerts = new(settings.TotalPoints, sizeof(float) * 4, ComputeBufferType.Structured);
        s.SetBuffer(ID, "_OutVerts", CBOutVerts);

        s.Dispatch(ID, THREADS_PER_AXIS, THREADS_PER_AXIS, THREADS_PER_AXIS);

        CBOffsets.Release();
        CBNoiseParams.Release();
        CBBoundsParams.Release();

        return CBOutVerts;

    }

}
