Shader "Unlit/CDShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [IntRange] _RefractionIterations("Refraction Iterations",Range(0,16)) = 8
        _Distance ("Distance",float) = 5000
        _CutOut("Outer Rad",Range(0,0.5)) = 0.25
        _CutIn("Inner Rad",Range(0,0.01)) = 0.005
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            
        //-----------------------------------------------------------------------------------------------------------------------------------
        //Spectral Zucconi 6
        //Originally by NVIDIA GPU GEMS: https://developer.nvidia.com/sites/all/modules/custom/gpugems/books/GPUGems/gpugems_ch08.html
        //Optimized by Alan Zucconi: https://www.alanzucconi.com/
        //NOT MINE THIS IS MAGIC NUMBER STUFF I DID NOT MAKE BESIDES REWRITING WITH HLSL SYNTAX

        float3 bump (float3 x, float3 yoffset)
        {
            float3 y = float3(1,1,1) - x * x;
            y = saturate(y-yoffset);
            return y;
        }
        
        float3 spectralZucconi (float w)
        {
            float x = saturate((w-400)/300);

            const float3 c1 = float3(3.54585104, 2.93225262, 2.41593945);
            const float3 x1 = float3(0.69549072, 0.49228336, 0.27699880);
            const float3 y1 = float3(0.02312639, 0.15225084, 0.52607955);

            const float3 c2 = float3(3.90307140, 3.21182957, 3.96587128);
            const float3 x2 = float3(0.11748627, 0.86755042, 0.66077860);
            const float3 y2 = float3(0.84897130, 0.88445281, 0.73949448);

            return bump(c1 * (x - x1), y1) + bump(c2 * (x - x2), y2) ;
        }
       // -----------------------------------------------------------------------------------------------------------------------------------

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float3 _MainLightDirection;
            float3 _MainLightColor;
            float _Distance;
            int _RefractionIterations;
            float _CutOut;
            float _CutIn;

            float4 frag (v2f i) : SV_Target
            {
                float2 d = i.uv - 0.5;
                float r = d.x * d.x + d.y * d.y;
                if(r >= _CutOut || r <= _CutIn) discard; //CD cutout

                float3 col = tex2D(_MainTex, i.uv) * _MainLightColor;

                float2 uvNorm = normalize(i.uv * 2 - 1); //remap
                float3 uvTan = float3(-uvNorm.y, 0, uvNorm.x); //tangent uv (object space)
                float3 tanWS = normalize(mul(unity_ObjectToWorld, float4(uvTan,0))).xyz; //tangent uv (world space)

                float cosThetaL = dot(_MainLightDirection,tanWS);
                float3 viewDir = _WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld,i.vertex).xyz;
                float cosThetaV = dot(viewDir,tanWS);
                float u = abs(cosThetaL - cosThetaV);
                if(u == 0) return float4(col,1);  //No iridesence here

                for(int i = 0; i < _RefractionIterations; ++i)
                {
                   col += spectralZucconi(u * _Distance / (i+1));            
                }
                return float4(col,1);
            }
            ENDCG
        }
    }
}
