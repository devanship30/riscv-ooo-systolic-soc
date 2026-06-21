// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_passthrough.h for the primary calling header

#include "Vtb_passthrough__pch.h"
#include "Vtb_passthrough___024root.h"

VL_ATTR_COLD void Vtb_passthrough___024root___eval_static(Vtb_passthrough___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_passthrough__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_passthrough___024root___eval_static\n"); );
}

VL_ATTR_COLD void Vtb_passthrough___024root___eval_final(Vtb_passthrough___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_passthrough__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_passthrough___024root___eval_final\n"); );
}

VL_ATTR_COLD void Vtb_passthrough___024root___eval_settle(Vtb_passthrough___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_passthrough__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_passthrough___024root___eval_settle\n"); );
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_passthrough___024root___dump_triggers__act(Vtb_passthrough___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_passthrough__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_passthrough___024root___dump_triggers__act\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VactTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 0 is active: @(posedge tb_passthrough.clk or negedge tb_passthrough.rst_n)\n");
    }
    if ((2ULL & vlSelf->__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 1 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_passthrough___024root___dump_triggers__nba(Vtb_passthrough___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_passthrough__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_passthrough___024root___dump_triggers__nba\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VnbaTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 0 is active: @(posedge tb_passthrough.clk or negedge tb_passthrough.rst_n)\n");
    }
    if ((2ULL & vlSelf->__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 1 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vtb_passthrough___024root___ctor_var_reset(Vtb_passthrough___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_passthrough__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_passthrough___024root___ctor_var_reset\n"); );
    // Body
    vlSelf->tb_passthrough__DOT__clk = VL_RAND_RESET_I(1);
    vlSelf->tb_passthrough__DOT__rst_n = VL_RAND_RESET_I(1);
    vlSelf->tb_passthrough__DOT__i_8bit = VL_RAND_RESET_I(8);
    vlSelf->tb_passthrough__DOT__o_8bit = VL_RAND_RESET_I(8);
    vlSelf->__Vdlyvval__tb_passthrough__DOT__clk__v0 = VL_RAND_RESET_I(1);
    vlSelf->__Vdlyvset__tb_passthrough__DOT__clk__v0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__tb_passthrough__DOT__clk__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vtrigprevexpr___TOP__tb_passthrough__DOT__rst_n__0 = VL_RAND_RESET_I(1);
}
