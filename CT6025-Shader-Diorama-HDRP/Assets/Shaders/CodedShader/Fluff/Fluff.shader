Shader "Unlit/Fluff"
{
  Properties
{
    _MainTex( "Main Texture" , 2D) =  "white"  {}
    _FluffNoise( "Fluff Noise" , 2D) =  "white"  {}
    _FluffNoiseScale("Fluff Noise Scale",Range(0.001,2)) = 1
    [IntRange] _ShellCount( "Shells" , Range( 1 ,  256 )) =  64
    _ShellStep( "Shell Step" , Range( 0.0 ,  0.01 )) =  0.001 
    _AlphaCutoff( "Alpha Cutout" , Range( 0.0 ,  1.0 )) =  0.1 
    _Occlusion("Occlusion",Range(0,1)) = 0.2
    _depthOffset("depth Offset",Vector) = (0,0,0,0)
    _WindVector("Wind Vector",Vector) = (0,0,0,0)
    _WindVector2("Wind Vector 2", Vector) = (0,0,0,0)
    _WindFrequency("Wind Frequency",Vector) = (0,0,0,0)
    _WindFrequency2("Wind Frequency 2",Vector) = (0,0,0,0)
    _FluffRepelStrength("Repel Strength",Range(0,10)) = 0
    _FluffRepelDistance("Repel Distance",Range(0.1,10)) = 0
    _FluffRepelPosition("Repel Position", Vector) = (0,0,0,0)
    
    [IntRange] _LODScalar("LOD Scalar",Range(1,8)) = 1
}

SubShader
{
    LOD 200
    Tags  { "RenderType"  =  "Opaque"  "IgnoreProjector"  =  "True" }

    ZWrite On
    Cull Back
    Pass
    {
        HLSLPROGRAM
        #define LODScalar 1
        #define invLODScalar 1/LODScalar
        #include  "FluffInclude.hlsl"

        #pragma vertex vert 
        #pragma require geometry 
        #pragma geometry geom  
        #pragma fragment frag 
                                                                                                  
        ENDHLSL

    }


    Pass 
    {   
        Tags { "LightMode" = "ShadowCaster" }

        ZWrite On 
        ZTest LEqual
        ColorMask 0

        HLSLPROGRAM
        #include "FluffInclude.hlsl"
        
        #pragma vertex vert 
        #pragma require geometry 
        #pragma geometry geom  
        #pragma fragment shadowFrag
        
        ENDHLSL
    }

}


}