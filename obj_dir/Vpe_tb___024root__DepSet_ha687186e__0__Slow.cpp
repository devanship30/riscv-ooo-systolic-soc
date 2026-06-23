// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vpe_tb.h for the primary calling header

#include "Vpe_tb__pch.h"
#include "Vpe_tb___024root.h"

VL_ATTR_COLD void Vpe_tb___024root___eval_static(Vpe_tb___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe_tb___024root___eval_static\n"); );
}

VL_ATTR_COLD void Vpe_tb___024root___eval_final(Vpe_tb___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe_tb___024root___eval_final\n"); );
}

VL_ATTR_COLD void Vpe_tb___024root___eval_settle(Vpe_tb___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe_tb___024root___eval_settle\n"); );
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vpe_tb___024root___dump_triggers__act(Vpe_tb___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe_tb___024root___dump_triggers__act\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VactTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 0 is active: @(posedge pe_tb.clk or negedge pe_tb.rst_n)\n");
    }
    if ((2ULL & vlSelf->__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 1 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
    if ((4ULL & vlSelf->__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 2 is active: @(posedge pe_tb.clk)\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vpe_tb___024root___dump_triggers__nba(Vpe_tb___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe_tb___024root___dump_triggers__nba\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VnbaTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 0 is active: @(posedge pe_tb.clk or negedge pe_tb.rst_n)\n");
    }
    if ((2ULL & vlSelf->__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 1 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
    if ((4ULL & vlSelf->__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 2 is active: @(posedge pe_tb.clk)\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vpe_tb___024root___ctor_var_reset(Vpe_tb___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe_tb___024root___ctor_var_reset\n"); );
    // Body
    vlSelf->pe_tb__DOT__clk = VL_RAND_RESET_I(1);
    vlSelf->pe_tb__DOT__rst_n = VL_RAND_RESET_I(1);
    vlSelf->pe_tb__DOT__load_en = VL_RAND_RESET_I(1);
    vlSelf->pe_tb__DOT__in_left = VL_RAND_RESET_I(8);
    vlSelf->pe_tb__DOT__in_top = VL_RAND_RESET_I(32);
    vlSelf->pe_tb__DOT__out_right = VL_RAND_RESET_I(8);
    vlSelf->pe_tb__DOT__out_bottom = VL_RAND_RESET_I(32);
    vlSelf->pe_tb__DOT__uut__DOT__weight_reg = VL_RAND_RESET_I(8);
    vlSelf->__Vdlyvval__pe_tb__DOT__clk__v0 = VL_RAND_RESET_I(1);
    vlSelf->__Vdlyvset__pe_tb__DOT__clk__v0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__pe_tb__DOT__clk__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vtrigprevexpr___TOP__pe_tb__DOT__rst_n__0 = VL_RAND_RESET_I(1);
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        vlSelf->__Vm_traceActivity[__Vi0] = 0;
    }
}
