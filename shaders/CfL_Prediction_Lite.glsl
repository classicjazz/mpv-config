// Revised 02/20/25
// https://github.com/Artoriuz/glsl-chroma-from-luma-prediction

// MIT License

// Copyright (c) 2023 João Chrisóstomo

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

//!HOOK CHROMA
//!BIND LUMA
//!BIND HOOKED
//!SAVE LUMA_LOWRES
//!WIDTH CHROMA.w
//!HEIGHT CHROMA.h
//!WHEN CHROMA.w LUMA.w <
//!DESC Chroma From Luma Prediction (Downscaling Luma)

vec4 hook() {
    return LUMA_texOff(0);
}

//!HOOK CHROMA
//!BIND HOOKED
//!BIND LUMA
//!BIND LUMA_LOWRES
//!WHEN CHROMA.w LUMA.w <
//!WIDTH LUMA.w
//!HEIGHT LUMA.h
//!OFFSET ALIGN
//!DESC Chroma From Luma Prediction (Upscaling Chroma)

#define DEBUG 0

float comp_wd(vec2 v) {
    float d2 = min(v.x * v.x + v.y * v.y, 4.0);
    float d4 = d2 * d2;
    return (d4 - 8.0 * d2 + 16.0) * (d4 - 5.0 * d2 + 4.0);
}

vec4 hook() {
    float ar_strength = 0.8;
    float mix_coeff = 0.8;
    vec2 corr_exponent = vec2(4.0);

    vec4 output_pix = vec4(0.0, 0.0, 0.0, 1.0);
    float luma_zero = LUMA_texOff(0.0).x;

    vec2 pp = HOOKED_pos * HOOKED_size - vec2(0.5);
    vec2 fp = floor(pp);
    pp -= fp;

#ifdef HOOKED_gather
    vec2 quad_idx[4] = {{0.0, 0.0}, {2.0, 0.0}, {0.0, 2.0}, {2.0, 2.0}};

    vec4 luma_quads[4];
    vec4 chroma_quads[4][2];

    for (int i = 0; i < 4; i++) {
        luma_quads[i] = LUMA_LOWRES_gather(vec2((fp + quad_idx[i]) * HOOKED_pt), 0);
        chroma_quads[i][0] = HOOKED_gather(vec2((fp + quad_idx[i]) * HOOKED_pt), 0);
        chroma_quads[i][1] = HOOKED_gather(vec2((fp + quad_idx[i]) * HOOKED_pt), 1);
    }

    vec2 chroma_pixels[12];
    chroma_pixels[0]  = vec2(chroma_quads[0][0].z, chroma_quads[0][1].z);
    chroma_pixels[1]  = vec2(chroma_quads[1][0].w, chroma_quads[1][1].w);
    chroma_pixels[2]  = vec2(chroma_quads[0][0].x, chroma_quads[0][1].x);
    chroma_pixels[3]  = vec2(chroma_quads[0][0].y, chroma_quads[0][1].y);
    chroma_pixels[4]  = vec2(chroma_quads[1][0].x, chroma_quads[1][1].x);
    chroma_pixels[5]  = vec2(chroma_quads[1][0].y, chroma_quads[1][1].y);
    chroma_pixels[6]  = vec2(chroma_quads[2][0].w, chroma_quads[2][1].w);
    chroma_pixels[7]  = vec2(chroma_quads[2][0].z, chroma_quads[2][1].z);
    chroma_pixels[8]  = vec2(chroma_quads[3][0].w, chroma_quads[3][1].w);
    chroma_pixels[9]  = vec2(chroma_quads[3][0].z, chroma_quads[3][1].z);
    chroma_pixels[10] = vec2(chroma_quads[2][0].y, chroma_quads[2][1].y);
    chroma_pixels[11] = vec2(chroma_quads[3][0].x, chroma_quads[3][1].x);

    float luma_pixels[12];
    luma_pixels[0]  = luma_quads[0].z;
    luma_pixels[1]  = luma_quads[1].w;
    luma_pixels[2]  = luma_quads[0].x;
    luma_pixels[3]  = luma_quads[0].y;
    luma_pixels[4]  = luma_quads[1].x;
    luma_pixels[5]  = luma_quads[1].y;
    luma_pixels[6]  = luma_quads[2].w;
    luma_pixels[7]  = luma_quads[2].z;
    luma_pixels[8]  = luma_quads[3].w;
    luma_pixels[9]  = luma_quads[3].z;
    luma_pixels[10] = luma_quads[2].y;
    luma_pixels[11] = luma_quads[3].x;
#else
    vec2 pix_idx[12] = {             {0.5,-0.5}, {1.5,-0.5},
                        {-0.5, 0.5}, {0.5, 0.5}, {1.5, 0.5}, {2.5, 0.5},
                        {-0.5, 1.5}, {0.5, 1.5}, {1.5, 1.5}, {2.5, 1.5},
                                     {0.5, 2.5}, {1.5, 2.5}            };

    float luma_pixels[12];
    vec2 chroma_pixels[12];

    for (int i = 0; i < 12; i++) {
        luma_pixels[i] = LUMA_LOWRES_tex(vec2((fp + pix_idx[i]) * HOOKED_pt)).x;
        chroma_pixels[i] = HOOKED_tex(vec2((fp + pix_idx[i]) * HOOKED_pt)).xy;
    }
#endif

#if (DEBUG == 1)
    vec2 chroma_spatial = vec2(0.5);
    mix_coeff = 1.0;
#else
    float wd[12];
    float wt = 0.0;
    vec2 ct = vec2(0.0);

    vec2 chroma_min = min(min(min(chroma_pixels[3], chroma_pixels[4]), chroma_pixels[7]), chroma_pixels[8]);
    vec2 chroma_max = max(max(max(chroma_pixels[3], chroma_pixels[4]), chroma_pixels[7]), chroma_pixels[8]);

    const int dx[12] = { 0, 1,-1, 0, 1, 2,-1, 0, 1, 2, 0, 1};
    const int dy[12] = {-1,-1, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2};

    for (int i = 0; i < 12; i++) {
        wd[i] = comp_wd(vec2(dx[i], dy[i]) - pp);
        wt += wd[i];
        ct += wd[i] * chroma_pixels[i];
    }

    vec2 chroma_spatial = ct / wt;
    chroma_spatial = clamp(mix(chroma_spatial, clamp(chroma_spatial, chroma_min, chroma_max), ar_strength), 0.0, 1.0);
#endif

    float luma_avg = 0.0;
    float luma_var = 0.0;
    vec2 chroma_avg = vec2(0.0);
    vec2 chroma_var = vec2(0.0);
    vec2 luma_chroma_cov = vec2(0.0);

    for (int i = 0; i < 12; i++) {
        luma_avg += luma_pixels[i];
        chroma_avg += chroma_pixels[i];
    }

    luma_avg /= 12.0;
    chroma_avg /= 12.0;

    for (int i = 0; i < 12; i++) {
        luma_var += pow(luma_pixels[i] - luma_avg, 2.0);
        chroma_var += pow(chroma_pixels[i] - chroma_avg, vec2(2.0));
        luma_chroma_cov += (luma_pixels[i] - luma_avg) * (chroma_pixels[i] - chroma_avg);
    }

    vec2 corr = clamp(abs(luma_chroma_cov / max(sqrt(luma_var * chroma_var), 1e-6)), 0.0, 1.0);

    vec2 alpha = luma_chroma_cov / max(luma_var, 1e-6);
    vec2 beta = chroma_avg - alpha * luma_avg;
    vec2 chroma_pred = clamp(alpha * luma_zero + beta, 0.0, 1.0);

    output_pix.xy = mix(chroma_spatial, chroma_pred, pow(corr, corr_exponent) * mix_coeff);
    output_pix.xy = clamp(output_pix.xy, 0.0, 1.0);
    return output_pix;
}