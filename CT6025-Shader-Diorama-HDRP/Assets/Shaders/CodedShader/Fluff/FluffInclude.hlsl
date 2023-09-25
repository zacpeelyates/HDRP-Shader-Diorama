#ifndef FLUFF_INCLUDE
#define FLUFF_INCLUDE
                                                                             
        int _ShellCount;
        float  _ShellStep;
        float  _AlphaCutoff;

        sampler2D _FluffNoise;
        float4 _FluffNoise_ST;
        float _FluffNoiseScale;
        sampler2D _MainTex;
        float4 _MainTex_ST;
        float _Occlusion;
        float4 _depthOffset;

        float4 _WindVector;
        float4 _WindVector2;
        float4 _WindFrequency;
        float4 _WindFrequency2;

        float _FluffRepelStrength;
        float4 _FluffRepelPosition;
        float _FluffRepelDistance;

        int _LODScalar;

         struct  appdata
        {
            float4 vertex : POSITION;
            float3 normal   : NORMAL;
            float4 tangent  : TANGENT;
            float2 uv         : TEXCOORD0;
        };

         struct  v2g
        {
            float4 vertex   : SV_POSITION;
            float2 colorUV  : TEXCOORD0;
            float2 fluffUV  : TEXCOORD1;
            float   depth   : TEXCOORD3;
        };

        #include "UnityCG.cginc"

        appdata vert(appdata a)
        {
             return  a;
        }

         void  AppendShellVertex(inout TriangleStream<v2g> stream, appdata a,  int  i)
        {
            v2g output = (v2g) 0 ;
            float depth = ( float )i / _ShellCount;
            float offset = pow(depth,_depthOffset.w);
            float3 wind = sin(_Time.w * _WindFrequency.xyz + a.vertex * _WindVector.w) * _WindVector.xyz * offset;
            float3 wind2 = cos(_Time.w * _WindFrequency2.xyz + a.vertex * _WindVector2.w) * _WindVector2.xyz * offset;
            
            float3 movement = _depthOffset.xyz * offset;

            float3 posWS = mul(unity_ObjectToWorld,float4(a.vertex.xyz,1)).xyz;
            float3 normalWS = mul(a.normal, (float3x3)unity_WorldToObject); //inverse transpose normals
            float3 dist = posWS - _FluffRepelPosition.xyz;
            float mag = sqrt(dist.x * dist.x + dist.y * dist.y + dist.z * dist.z);
            float3 repel = float3(0,0,0); 
            float3 norm = 0;
            if(mag != 0) norm = normalize(dist);
            if(mag <= _FluffRepelDistance) repel = lerp(_FluffRepelStrength,0,mag/_FluffRepelDistance) * norm;

            posWS += normalize(normalWS + movement + wind + wind2 + repel) * (_ShellStep * i);
            
        
            output.vertex =  mul(UNITY_MATRIX_VP,float4(posWS,1));
            output.colorUV = TRANSFORM_TEX(a.uv, _MainTex);
            output.fluffUV = TRANSFORM_TEX(a.uv, _FluffNoise);
            output.depth = depth;
           
            stream.Append(output);
        }

        [maxvertexcount( 96 )]
         void  geom(triangle appdata a[ 3 ], inout TriangleStream<v2g> stream)
        {
            for  ( float  i =  0 ; i < _ShellCount; i+= _LODScalar)
            {
                 AppendShellVertex(stream, a[0], i);
                 AppendShellVertex(stream, a[1], i);
                 AppendShellVertex(stream, a[2], i);
                
                 stream.RestartStrip();
            }
        }

        float4 frag(v2g o) : SV_Target
        {
            float4 FluffNoiseSample = tex2D(_FluffNoise, o.fluffUV * _FluffNoiseScale);
            float a = FluffNoiseSample.r * (1-o.depth);
            if  (o.depth >  0.0  && a < _AlphaCutoff) discard;

            float3 baseColor = tex2D(_MainTex, o.colorUV);
            float occlusion = lerp(1 - _Occlusion, 1, o.depth);
            return float4(baseColor * occlusion,a);
        }


        void shadowFrag (v2g o, out float4 col : SV_TARGET, out float depth : SV_DEPTH)
        {
            float4 FluffNoiseSample = tex2D(_FluffNoise, o.fluffUV);
            float a = FluffNoiseSample.r * (1-o.depth);
            if  (o.depth >  0.0  && a < _AlphaCutoff) discard;

            col = depth = o.vertex.z / o.vertex.w;
        } 
#endif