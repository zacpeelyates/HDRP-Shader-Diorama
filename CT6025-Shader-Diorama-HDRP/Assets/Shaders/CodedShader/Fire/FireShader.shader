Shader "Unlit/FireShader"
{
    Properties
    {
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _GradTex ("Grad Texture",2D) = "white" {}
        
        _Top("TopCol", color) = (1,1,1,1)
        _Middle("MiddleCol", color) = (1,1,1,1)
        _Bottom("BottomCol", color) = (1,1,1,1)

        _GradScale("GradScale",float) = 1
        _NoiseScale("NoiseScale",float) = 1

        _StepA("StepA",Range(0,1)) = 0.25
        _StepB("StepB",Range(0,1)) = 0.5
        _Offset("Offset",Range(-1,1)) = 0

        _Speed("Speed",float) = 1

        _Scale("Scale",float) = 1

    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent"  }
       
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 100
		Cull Off
		ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

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

            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;

            sampler2D _GradTex;
            float4 _GradTex_ST;

            float _StepA;
            float _StepB;

            float4 _Top;
            float4 _Middle;
            float4 _Bottom;

            float _Speed;
            float _Scale;

            float _NoiseScale;
            float _GradScale;
            float _Offset;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //Scale
                i.uv = frac(i.uv * _Scale);
                
                //Animate
                float2 timeOffset = float2(0,_Time.x * _Speed);
                
                //Sample
                float noise = tex2D(_NoiseTex, (i.uv * _NoiseScale) - timeOffset).r;
                float grad = tex2D(_GradTex, i.uv * _GradScale).r + _Offset;

                //Bounds
                float s  = step(noise, grad);
                float s2 = step(noise,grad - _StepA);
                float s3 = step(noise,grad - _StepB);

                //Color
                float4 col = float4(lerp(_Top,_Bottom,s-s2));
                return lerp(col, _Middle, s2-s3);
            }
            ENDCG
        }
    }
}
