// Revised 06/19/22
// https://github.com/Artoriuz/glsl-chroma-from-luma-prediction
//
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
//!HEIGHT LUMA.h
//!WHEN CHROMA.w LUMA.w <
//!DESC Chroma From Luma Prediction (Downscaling Luma 1st Step)

vec4 hook() {
    float factor = ceil(LUMA_size.x / HOOKED_size.x);
    int start = int(ceil(-factor / 2.0 - 0.5));
    int end = int(floor(factor / 2.0 - 0.5));

    float output_luma = 0.0;
    int wt = 0;
    for (int dx = start; dx <= end; dx++) {
        output_luma += LUMA_texOff(vec2(dx + 0.5, 0.0)).x;
        wt++;
    }
    vec4 output_pix = vec4(output_luma / float(wt), 0.0, 0.0, 1.0);
    return output_pix;
}

//!HOOK CHROMA
//!BIND LUMA_LOWRES
//!BIND HOOKED
//!SAVE LUMA_LOWRES
//!WIDTH CHROMA.w
//!HEIGHT CHROMA.h
//!WHEN CHROMA.w LUMA.w <
//!DESC Chroma From Luma Prediction (Downscaling Luma 2nd Step)

vec4 hook() {
    float factor = ceil(LUMA_LOWRES_size.y / HOOKED_size.y);
    int start = int(ceil(-factor / 2.0 - 0.5));
    int end = int(floor(factor / 2.0 - 0.5));

    float output_luma = 0.0;
    int wt = 0;
    for (int dy = start; dy <= end; dy++) {
        output_luma += LUMA_LOWRES_texOff(vec2(0.0, dy + 0.5)).x;
        wt++;
    }
    vec4 output_pix = vec4(output_luma / float(wt), 0.0, 0.0, 1.0);
    return output_pix;
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

#define USE_12_TAP_REGRESSION 1
#define USE_4_TAP_REGRESSION 0

float comp_wd(vec2 distance) {
    float d2 = min(pow(length(distance), 2.0), 4.0);
    return (25.0 / 16.0 * pow(2.0 / 5.0 * d2 - 1.0, 2.0) - (25.0 / 16.0 - 1.0)) * pow(1.0 / 4.0 * d2 - 1.0, 2.0);
}

vec4 hook() {
    float ar_strength = 0.75;
    float mix_coeff = 0.5;

    vec4 output_pix = vec4(0.0, 0.0, 0.0, 1.0);
    float luma_zero = LUMA_texOff(0.0).x;

    vec2 pp = HOOKED_pos * HOOKED_size - vec2(0.5);
    vec2 fp = floor(pp);
    pp -= fp;
#ifdef HOOKED_gather
    vec4 chroma_quads[4][2];
    chroma_quads[0][0] = HOOKED_gather(vec2((fp + vec2(0.0, 0.0)) * HOOKED_pt), 0);
    chroma_quads[1][0] = HOOKED_gather(vec2((fp + vec2(2.0, 0.0)) * HOOKED_pt), 0);
    chroma_quads[2][0] = HOOKED_gather(vec2((fp + vec2(0.0, 2.0)) * HOOKED_pt), 0);
    chroma_quads[3][0] = HOOKED_gather(vec2((fp + vec2(2.0, 2.0)) * HOOKED_pt), 0);
    chroma_quads[0][1] = HOOKED_gather(vec2((fp + vec2(0.0, 0.0)) * HOOKED_pt), 1);
    chroma_quads[1][1] = HOOKED_gather(vec2((fp + vec2(2.0, 0.0)) * HOOKED_pt), 1);
    chroma_quads[2][1] = HOOKED_gather(vec2((fp + vec2(0.0, 2.0)) * HOOKED_pt), 1);
    chroma_quads[3][1] = HOOKED_gather(vec2((fp + vec2(2.0, 2.0)) * HOOKED_pt), 1);

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
#if (USE_12_TAP_REGRESSION == 1 || USE_4_TAP_REGRESSION == 1)
    vec4 luma_quads[4];
    luma_quads[0] = LUMA_LOWRES_gather(vec2((fp + vec2(0.0, 0.0)) * HOOKED_pt), 0);
    luma_quads[1] = LUMA_LOWRES_gather(vec2((fp + vec2(2.0, 0.0)) * HOOKED_pt), 0);
    luma_quads[2] = LUMA_LOWRES_gather(vec2((fp + vec2(0.0, 2.0)) * HOOKED_pt), 0);
    luma_quads[3] = LUMA_LOWRES_gather(vec2((fp + vec2(2.0, 2.0)) * HOOKED_pt), 0);

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
#endif
#else
    vec2 chroma_pixels[12];
    chroma_pixels[0]  = HOOKED_tex(vec2((fp + vec2(0.5, -0.5)) * HOOKED_pt)).xy;
    chroma_pixels[1]  = HOOKED_tex(vec2((fp + vec2(1.5, -0.5)) * HOOKED_pt)).xy;
    chroma_pixels[2]  = HOOKED_tex(vec2((fp + vec2(-0.5, 0.5)) * HOOKED_pt)).xy;
    chroma_pixels[3]  = HOOKED_tex(vec2((fp + vec2( 0.5, 0.5)) * HOOKED_pt)).xy;
    chroma_pixels[4]  = HOOKED_tex(vec2((fp + vec2( 1.5, 0.5)) * HOOKED_pt)).xy;
    chroma_pixels[5]  = HOOKED_tex(vec2((fp + vec2( 2.5, 0.5)) * HOOKED_pt)).xy;
    chroma_pixels[6]  = HOOKED_tex(vec2((fp + vec2(-0.5, 1.5)) * HOOKED_pt)).xy;
    chroma_pixels[7]  = HOOKED_tex(vec2((fp + vec2( 0.5, 1.5)) * HOOKED_pt)).xy;
    chroma_pixels[8]  = HOOKED_tex(vec2((fp + vec2( 1.5, 1.5)) * HOOKED_pt)).xy;
    chroma_pixels[9]  = HOOKED_tex(vec2((fp + vec2( 2.5, 1.5)) * HOOKED_pt)).xy;
    chroma_pixels[10] = HOOKED_tex(vec2((fp + vec2( 0.5, 2.5)) * HOOKED_pt)).xy;
    chroma_pixels[11] = HOOKED_tex(vec2((fp + vec2( 1.5, 2.5)) * HOOKED_pt)).xy;
#if (USE_12_TAP_REGRESSION == 1 || USE_4_TAP_REGRESSION == 1)
    float luma_pixels[12];
    luma_pixels[0]  = LUMA_LOWRES_tex(vec2((fp + vec2(0.5, -0.5)) * HOOKED_pt)).x;
    luma_pixels[1]  = LUMA_LOWRES_tex(vec2((fp + vec2(1.5, -0.5)) * HOOKED_pt)).x;
    luma_pixels[2]  = LUMA_LOWRES_tex(vec2((fp + vec2(-0.5, 0.5)) * HOOKED_pt)).x;
    luma_pixels[3]  = LUMA_LOWRES_tex(vec2((fp + vec2( 0.5, 0.5)) * HOOKED_pt)).x;
    luma_pixels[4]  = LUMA_LOWRES_tex(vec2((fp + vec2( 1.5, 0.5)) * HOOKED_pt)).x;
    luma_pixels[5]  = LUMA_LOWRES_tex(vec2((fp + vec2( 2.5, 0.5)) * HOOKED_pt)).x;
    luma_pixels[6]  = LUMA_LOWRES_tex(vec2((fp + vec2(-0.5, 1.5)) * HOOKED_pt)).x;
    luma_pixels[7]  = LUMA_LOWRES_tex(vec2((fp + vec2( 0.5, 1.5)) * HOOKED_pt)).x;
    luma_pixels[8]  = LUMA_LOWRES_tex(vec2((fp + vec2( 1.5, 1.5)) * HOOKED_pt)).x;
    luma_pixels[9]  = LUMA_LOWRES_tex(vec2((fp + vec2( 2.5, 1.5)) * HOOKED_pt)).x;
    luma_pixels[10] = LUMA_LOWRES_tex(vec2((fp + vec2( 0.5, 2.5)) * HOOKED_pt)).x;
    luma_pixels[11] = LUMA_LOWRES_tex(vec2((fp + vec2( 1.5, 2.5)) * HOOKED_pt)).x;
#endif
#endif
    vec2 chroma_min = vec2(1e8);
    chroma_min = min(chroma_min, chroma_pixels[3]);
    chroma_min = min(chroma_min, chroma_pixels[4]);
    chroma_min = min(chroma_min, chroma_pixels[7]);
    chroma_min = min(chroma_min, chroma_pixels[8]);

    vec2 chroma_max = vec2(1e-8);
    chroma_max = max(chroma_max, chroma_pixels[3]);
    chroma_max = max(chroma_max, chroma_pixels[4]);
    chroma_max = max(chroma_max, chroma_pixels[7]);
    chroma_max = max(chroma_max, chroma_pixels[8]);

    float wd[12];
    wd[0]  = comp_wd(vec2( 0.0,-1.0) - pp);
    wd[1]  = comp_wd(vec2( 1.0,-1.0) - pp);
    wd[2]  = comp_wd(vec2(-1.0, 0.0) - pp);
    wd[3]  = comp_wd(vec2( 0.0, 0.0) - pp);
    wd[4]  = comp_wd(vec2( 1.0, 0.0) - pp);
    wd[5]  = comp_wd(vec2( 2.0, 0.0) - pp);
    wd[6]  = comp_wd(vec2(-1.0, 1.0) - pp);
    wd[7]  = comp_wd(vec2( 0.0, 1.0) - pp);
    wd[8]  = comp_wd(vec2( 1.0, 1.0) - pp);
    wd[9]  = comp_wd(vec2( 2.0, 1.0) - pp);
    wd[10] = comp_wd(vec2( 0.0, 2.0) - pp);
    wd[11] = comp_wd(vec2( 1.0, 2.0) - pp);

    float wt = 0.0;
    for (int i = 0; i < 12; i++) {
        wt += wd[i];
    }

    vec2 ct = vec2(0.0);
    for (int i = 0; i < 12; i++) {
        ct += wd[i] * chroma_pixels[i];
    }

    vec2 chroma_spatial = clamp(ct / wt, 0.0, 1.0);
    chroma_spatial = mix(chroma_spatial, clamp(chroma_spatial, chroma_min, chroma_max), ar_strength);
#if (USE_12_TAP_REGRESSION == 1 || USE_4_TAP_REGRESSION == 1)
    float luma_avg_12 = 0.0;
    for(int i = 0; i < 12; i++) {
        luma_avg_12 += luma_pixels[i];
    }
    luma_avg_12 /= 12.0;

    float luma_var_12 = 0.0;
    for(int i = 0; i < 12; i++) {
        luma_var_12 += pow(luma_pixels[i] - luma_avg_12, 2.0);
    }

    vec2 chroma_avg_12 = vec2(0.0);
    for(int i = 0; i < 12; i++) {
        chroma_avg_12 += chroma_pixels[i];
    }
    chroma_avg_12 /= 12.0;

    vec2 chroma_var_12 = vec2(0.0);
    for(int i = 0; i < 12; i++) {
        chroma_var_12 += pow(chroma_pixels[i] - chroma_avg_12, vec2(2.0));
    }

    vec2 luma_chroma_cov_12 = vec2(0.0);
    for(int i = 0; i < 12; i++) {
        luma_chroma_cov_12 += (luma_pixels[i] - luma_avg_12) * (chroma_pixels[i] - chroma_avg_12);
    }

    vec2 corr = abs(luma_chroma_cov_12 / max(sqrt(luma_var_12 * chroma_var_12), 1e-6));
    corr = clamp(corr, 0.0, 1.0);
#endif
#if (USE_12_TAP_REGRESSION == 1)
    vec2 alpha_12 = luma_chroma_cov_12 / max(luma_var_12, 1e-6);
    vec2 beta_12 = chroma_avg_12 - alpha_12 * luma_avg_12;
    vec2 chroma_pred_12 = clamp(alpha_12 * luma_zero + beta_12, 0.0, 1.0);
#endif
#if (USE_4_TAP_REGRESSION == 1)
    float luma_avg_4 = 0.0;
    luma_avg_4 += luma_pixels[3];
    luma_avg_4 += luma_pixels[4];
    luma_avg_4 += luma_pixels[7];
    luma_avg_4 += luma_pixels[8];
    luma_avg_4 /= 4.0;

    float luma_var_4 = 0.0;
    luma_var_4 += pow(luma_pixels[3] - luma_avg_4, 2.0);
    luma_var_4 += pow(luma_pixels[4] - luma_avg_4, 2.0);
    luma_var_4 += pow(luma_pixels[7] - luma_avg_4, 2.0);
    luma_var_4 += pow(luma_pixels[8] - luma_avg_4, 2.0);

    vec2 chroma_avg_4 = vec2(0.0);
    chroma_avg_4 += chroma_pixels[3];
    chroma_avg_4 += chroma_pixels[4];
    chroma_avg_4 += chroma_pixels[7];
    chroma_avg_4 += chroma_pixels[8];
    chroma_avg_4 /= 4.0;

    vec2 luma_chroma_cov_4 = vec2(0.0);
    luma_chroma_cov_4 += (luma_pixels[3] - luma_avg_4) * (chroma_pixels[3] - chroma_avg_4);
    luma_chroma_cov_4 += (luma_pixels[4] - luma_avg_4) * (chroma_pixels[4] - chroma_avg_4);
    luma_chroma_cov_4 += (luma_pixels[7] - luma_avg_4) * (chroma_pixels[7] - chroma_avg_4);
    luma_chroma_cov_4 += (luma_pixels[8] - luma_avg_4) * (chroma_pixels[8] - chroma_avg_4);

    vec2 alpha_4 = luma_chroma_cov_4 / max(luma_var_4, 1e-4);
    vec2 beta_4 = chroma_avg_4 - alpha_4 * luma_avg_4;
    vec2 chroma_pred_4 = clamp(alpha_4 * luma_zero + beta_4, 0.0, 1.0);
#endif
#if (USE_12_TAP_REGRESSION == 1 && USE_4_TAP_REGRESSION == 1)
    output_pix.xy = mix(chroma_spatial, mix(chroma_pred_4, chroma_pred_12, 0.5), pow(corr, vec2(2.0)) * mix_coeff);
#elif (USE_12_TAP_REGRESSION == 1 && USE_4_TAP_REGRESSION == 0)
    output_pix.xy = mix(chroma_spatial, chroma_pred_12, pow(corr, vec2(2.0)) * mix_coeff);
#elif (USE_12_TAP_REGRESSION == 0 && USE_4_TAP_REGRESSION == 1)
    output_pix.xy = mix(chroma_spatial, chroma_pred_4, pow(corr, vec2(2.0)) * mix_coeff);
#else
    output_pix.xy = chroma_spatial;
#endif
    output_pix.xy = clamp(output_pix.xy, 0.0, 1.0);
    return output_pix;
}
