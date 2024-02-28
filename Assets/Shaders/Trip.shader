Shader "Custom/Trip"
{
    Properties
    {
        _MainTex ("iChannel0", 2D) = "white" {}
        _SecondTex ("iChannel1", 2D) = "white" {}
        _ThirdTex ("iChannel2", 2D) = "white" {}
        _FourthTex ("iChannel3", 2D) = "white" {}
        _Mouse ("Mouse", Vector) = (0.5, 0.5, 0.5, 0.5)
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
    }
    SubShader
    {
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

            // Built-in properties
            sampler2D _MainTex;   float4 _MainTex_TexelSize;
            sampler2D _SecondTex; float4 _SecondTex_TexelSize;
            sampler2D _ThirdTex;  float4 _ThirdTex_TexelSize;
            sampler2D _FourthTex; float4 _FourthTex_TexelSize;
            float4 _Mouse;
            float _GammaCorrect;
            float _Resolution;

            // GLSL Compatability macros
            #define glsl_mod(x,y) (((x)-(y)*floor((x)/(y))))
            #define texelFetch(ch, uv, lod) tex2Dlod(ch, float4((uv).xy * ch##_TexelSize.xy + ch##_TexelSize.xy * 0.5, 0, lod))
            #define textureLod(ch, uv, lod) tex2Dlod(ch, float4(uv, 0, lod))
            #define iResolution float3(_Resolution, _Resolution, _Resolution)
            #define iFrame (floor(_Time.y / 60))
            #define iChannelTime float4(_Time.y, _Time.y, _Time.y, _Time.y)
            #define iDate float4(2020, 6, 18, 30)
            #define iSampleRate (44100)
            #define iChannelResolution float4x4(                      \
                _MainTex_TexelSize.z,   _MainTex_TexelSize.w,   0, 0, \
                _SecondTex_TexelSize.z, _SecondTex_TexelSize.w, 0, 0, \
                _ThirdTex_TexelSize.z,  _ThirdTex_TexelSize.w,  0, 0, \
                _FourthTex_TexelSize.z, _FourthTex_TexelSize.w, 0, 0)

            // Global access to uv data
            static v2f vertex_output;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv =  v.uv;
                return o;
            }

            float hash(float n)
            {
                return frac(sin(n)*43758.547);
            }

            float noise(in float3 x)
            {
                float3 p = floor(x);
                float3 f = frac(x);
                f = f*f*(3.-2.*f);
                float n = p.x+p.y*57.+113.*p.z;
                return lerp(lerp(lerp(hash(n+0.), hash(n+1.), f.x), lerp(hash(n+57.), hash(n+58.), f.x), f.y), lerp(lerp(hash(n+113.), hash(n+114.), f.x), lerp(hash(n+170.), hash(n+171.), f.x), f.y), f.z);
            }

            float3 noise3(in float3 x)
            {
                return float3(noise(x+float3(123.456, 0.567, 0.37)), noise(x+float3(0.11, 47.43, 19.17)), noise(x));
            }

            float bias(float x, float b)
            {
                return x/((1./b-2.)*(1.-x)+1.);
            }

            float gain(float x, float g)
            {
                float t = (1./g-2.)*(1.-2.*x);
                return x<0.5 ? x/(t+1.) : (t-x)/(t-1.);
            }

            float3x3 rotation(float angle, float3 axis)
            {
                float s = sin(-angle);
                float c = cos(-angle);
                float oc = 1.-c;
                float3 sa = axis*s;
                float3 oca = axis*oc;
                return transpose(float3x3(oca.x*axis+float3(c, -sa.z, sa.y), oca.y*axis+float3(sa.z, c, -sa.x), oca.z*axis+float3(-sa.y, sa.x, c)));
            }

            float3 fbm(float3 x, float H, float L, int oc)
            {
                float3 v = ((float3)0);
                float f = 1.;
                for (int i = 0;i<10; i++)
                {
                    if (i>=oc)
                        break;
                        
                    float w = pow(f, -H);
                    v += noise3(x)*w;
                    x *= L;
                    f *= L;
                }
                return v;
            }

            float3 smf(float3 x, float H, float L, int oc, float off)
            {
                float3 v = ((float3)1);
                float f = 1.;
                for (int i = 0;i<10; i++)
                {
                    if (i>=oc)
                        break;
                        
                    v *= off+f*(noise3(x)*2.-1.);
                    f *= H;
                    x *= L;
                }
                return v;
            }

            float4 frag (v2f __vertex_output) : SV_Target
            {
                vertex_output = __vertex_output;
                float4 fragColor = 0;
                float2 fragCoord = vertex_output.uv * _Resolution;
                float2 uv = fragCoord.xy/iResolution.xy;
                uv.x *= iResolution.x/iResolution.y;
                float time = _Time.y*1.276;
                float slow = time*0.002;
                uv *= 1.+0.5*slow*sin(slow*10.);
                float ts = time*0.37;
                float change = gain(frac(ts), 0.0008)+floor(ts);
                float3 p = float3(uv*0.2, slow+change);
                float3 axis = 4.*fbm(p, 0.5, 2., 8);
                float3 colorVec = 0.5*5.*fbm(p*0.3, 0.5, 2., 7);
                p += colorVec;
                float mag = 75000.;
                float3 colorMod = mag*smf(p, 0.7, 2., 8, 0.2);
                colorVec += colorMod;
                colorVec = mul(rotation(3.*length(axis)+slow*10., normalize(axis)),colorVec);
                colorVec *= 0.05;
                colorVec = pow(colorVec, ((float3)1./2.2));
                fragColor = float4(colorVec, 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}