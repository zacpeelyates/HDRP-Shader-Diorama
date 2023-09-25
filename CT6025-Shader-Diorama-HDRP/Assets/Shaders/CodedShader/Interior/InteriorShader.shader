Shader "Unlit/InteriorShader"
{
    Properties
    {
        _CubeArray ("CubeArray",CubeArray) = ""{}
        _MainTex ("Frame Texture",2D) = "white" {}
        _GlassTex("Glass Texture",2D) = "white" {}
        _RoomGrid("RoomGridSize",int) = 1
        _Opacity("Opacity",Range(0,1)) = 0
        _KeyColor("Key Color",color) = (1,1,1,1)
        _KeyStrength("KeyStrength",float) = 1
        _Depth("Depth",float) = 1

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Geometry"}
        LOD 100

        Pass
        {
            Cull Back 
            ZTest LEqual
            ZWrite On
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0
            #pragma require cubearray

            #include "UnityCG.cginc"


            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 tangent : TANGENT;

            };

            struct v2f
            {
               float4 vertex : SV_POSITION;
               float3 normal : TEXCOORD0;
               float4 tangent : TEXCOORD1;
               float2 uv : TEXCOORD2;
               float3 viewDir : TEXCOORD3;
                
            };

            float _Opacity;

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _GlassTex;
            float4 _GlassTex_ST;

            UNITY_DECLARE_TEXCUBEARRAY(_CubeArray);
            float4 _CubeArray_ST;

            int _SliceIndex;
            int _RoomGrid;

            float4 _KeyColor;
            float _KeyStrength;

            v2f vert (appdata v)
            {
                v2f o = (v2f)0; 
                o.vertex = mul(UNITY_MATRIX_MVP,v.vertex); //WorldSpace
                o.uv = TRANSFORM_TEX(v.uv,_CubeArray) * _RoomGrid;
                float4 camOS = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos,1)); //Object-Space
                float3 viewDir = v.vertex.xyz - camOS.xyz;
                float3 bitan = cross(v.normal,v.tangent.xyz) * v.tangent.w * unity_WorldTransformParams.w; //bitangent
                o.viewDir = float3(dot(viewDir,v.tangent.xyz), dot(viewDir,bitan) , dot(viewDir,v.normal)) * _CubeArray_ST.xyx;; //ViewDirection  
                return o;
            }

            float _Depth;

            float4 frag (v2f i) : SV_Target
            {
                //Interior Map
                float2 fracUV = frac(i.uv);
                float3 pos = float3(fracUV * 2.0 - 1.0, _Depth); //remap and apply depth
                float3 inverseViewDir = 1 / i.viewDir;

                //Parralax 
                float3 k = abs(inverseViewDir) - pos * inverseViewDir; 
                float kMin = min(min(k.x, k.y), k.z);
                pos += kMin * i.viewDir;

                //Sample cube at roomIndex in array
                float4 interior = float4(UNITY_SAMPLE_TEXCUBEARRAY(_CubeArray,float4(pos.xyz,(int)i.uv.x)).rgb,1);

                //Window Mask
                float4 window = tex2D(_MainTex,i.uv); 
                float3 diff = (_KeyColor - window).rgb;
                float difflength = length(diff);
                if(difflength < _KeyStrength)
                {
                    float3 glass = tex2D(_GlassTex,i.uv);
                    return float4(lerp(interior,glass,_Opacity).rgb,1);
                }

                return window;
            }



            ENDHLSL

        }
    }
}

