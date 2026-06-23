// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vpe_tb.h for the primary calling header

#include "Vpe_tb__pch.h"
#include "Vpe_tb___024root.h"

VlCoroutine Vpe_tb___024root___eval_initial__TOP__Vtiming__0(Vpe_tb___024root* vlSelf);
VlCoroutine Vpe_tb___024root___eval_initial__TOP__Vtiming__1(Vpe_tb___024root* vlSelf);

void Vpe_tb___024root___eval_initial(Vpe_tb___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe_tb___024root___eval_initial\n"); );
    // Body
    Vpe_tb___024root___eval_initial__TOP__Vtiming__0(vlSelf);
    Vpe_tb___024root___eval_initial__TOP__Vtiming__1(vlSelf);
    vlSelf->__Vtrigprevexpr___TOP__pe_tb__DOT__clk__0 
        = vlSelf->pe_tb__DOT__clk;
    vlSelf->__Vtrigprevexpr___TOP__pe_tb__DOT__rst_n__0 
        = vlSelf->pe_tb__DOT__rst_n;
}

VL_INLINE_OPT VlCoroutine Vpe_tb___024root___eval_initial__TOP__Vtiming__1(Vpe_tb___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe_tb___024root___eval_initial__TOP__Vtiming__1\n"); );
    // Body
    while (1U) {
        co_await vlSelf->__VdlySched.delay(0xaULL, 
                                           nullptr, 
                                           "tb/unit/ai_acc/pe_tb.sv", 
                                           13);
        vlSelf->__Vdlyvval__pe_tb__DOT__clk__v0 = (1U 
                                                   & (~ (IData)(vlSelf->pe_tb__DOT__clk)));
        vlSelf->__Vdlyvset__pe_tb__DOT__clk__v0 = 1U;
    }
}

void Vpe_tb___024root___eval_act(Vpe_tb___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe_tb___024root___eval_act\n"); );
}

VL_INLINE_OPT void Vpe_tb___024root___nba_sequent__TOP__0(Vpe_tb___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe_tb___024root___nba_sequent__TOP__0\n"); );
    // Body
    if (vlSelf->__Vdlyvset__pe_tb__DOT__clk__v0) {
        vlSelf->pe_tb__DOT__clk = vlSelf->__Vdlyvval__pe_tb__DOT__clk__v0;
        vlSelf->__Vdlyvset__pe_tb__DOT__clk__v0 = 0U;
    }
}

VL_INLINE_OPT void Vpe_tb___024root___nba_sequent__TOP__1(Vpe_tb___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe_tb___024root___nba_sequent__TOP__1\n"); );
    // Body
    if (vlSelf->pe_tb__DOT__rst_n) {
        vlSelf->pe_tb__DOT__out_right = vlSelf->pe_tb__DOT__in_left;
        if (vlSelf->pe_tb__DOT__load_en) {
            vlSelf->pe_tb__DOT__out_bottom = 0U;
            vlSelf->pe_tb__DOT__uut__DOT__weight_reg 
                = vlSelf->pe_tb__DOT__in_left;
        } else {
            vlSelf->pe_tb__DOT__out_bottom = (vlSelf->pe_tb__DOT__in_top 
                                              + VL_MULS_III(32, 
                                                            VL_EXTENDS_II(32,8, (IData)(vlSelf->pe_tb__DOT__in_left)), 
                                                            VL_EXTENDS_II(32,8, (IData)(vlSelf->pe_tb__DOT__uut__DOT__weight_reg))));
        }
    } else {
        vlSelf->pe_tb__DOT__out_right = 0U;
        vlSelf->pe_tb__DOT__out_bottom = 0U;
        vlSelf->pe_tb__DOT__uut__DOT__weight_reg = 0U;
    }
}

void Vpe_tb___024root___eval_nba(Vpe_tb___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe_tb___024root___eval_nba\n"); );
    // Body
    if ((2ULL & vlSelf->__VnbaTriggered.word(0U))) {
        Vpe_tb___024root___nba_sequent__TOP__0(vlSelf);
    }
    if ((1ULL & vlSelf->__VnbaTriggered.word(0U))) {
        Vpe_tb___024root___nba_sequent__TOP__1(vlSelf);
        vlSelf->__Vm_traceActivity[1U] = 1U;
    }
}

void Vpe_tb___024root___timing_resume(Vpe_tb___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe_tb___024root___timing_resume\n"); );
    // Body
    if ((4ULL & vlSelf->__VactTriggered.word(0U))) {
        vlSelf->__VtrigSched_h0332e823__0.resume("@(posedge pe_tb.clk)");
    }
    if ((2ULL & vlSelf->__VactTriggered.word(0U))) {
        vlSelf->__VdlySched.resume();
    }
}

void Vpe_tb___024root___timing_commit(Vpe_tb___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe_tb___024root___timing_commit\n"); );
    // Body
    if ((! (4ULL & vlSelf->__VactTriggered.word(0U)))) {
        vlSelf->__VtrigSched_h0332e823__0.commit("@(posedge pe_tb.clk)");
    }
}

void Vpe_tb___024root___eval_triggers__act(Vpe_tb___024root* vlSelf);

bool Vpe_tb___024root___eval_phase__act(Vpe_tb___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe_tb___024root___eval_phase__act\n"); );
    // Init
    VlTriggerVec<3> __VpreTriggered;
    CData/*0:0*/ __VactExecute;
    // Body
    Vpe_tb___024root___eval_triggers__act(vlSelf);
    Vpe_tb___024root___timing_commit(vlSelf);
    __VactExecute = vlSelf->__VactTriggered.any();
    if (__VactExecute) {
        __VpreTriggered.andNot(vlSelf->__VactTriggered, vlSelf->__VnbaTriggered);
        vlSelf->__VnbaTriggered.thisOr(vlSelf->__VactTriggered);
        Vpe_tb___024root___timing_resume(vlSelf);
        Vpe_tb___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vpe_tb___024root___eval_phase__nba(Vpe_tb___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe_tb___024root___eval_phase__nba\n"); );
    // Init
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = vlSelf->__VnbaTriggered.any();
    if (__VnbaExecute) {
        Vpe_tb___024root___eval_nba(vlSelf);
        vlSelf->__VnbaTriggered.clear();
    }
    return (__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vpe_tb___024root___dump_triggers__nba(Vpe_tb___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vpe_tb___024root___dump_triggers__act(Vpe_tb___024root* vlSelf);
#endif  // VL_DEBUG

void Vpe_tb___024root___eval(Vpe_tb___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe_tb___024root___eval\n"); );
    // Init
    IData/*31:0*/ __VnbaIterCount;
    CData/*0:0*/ __VnbaContinue;
    // Body
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        if (VL_UNLIKELY((0x64U < __VnbaIterCount))) {
#ifdef VL_DEBUG
            Vpe_tb___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("tb/unit/ai_acc/pe_tb.sv", 1, "", "NBA region did not converge.");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        __VnbaContinue = 0U;
        vlSelf->__VactIterCount = 0U;
        vlSelf->__VactContinue = 1U;
        while (vlSelf->__VactContinue) {
            if (VL_UNLIKELY((0x64U < vlSelf->__VactIterCount))) {
#ifdef VL_DEBUG
                Vpe_tb___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("tb/unit/ai_acc/pe_tb.sv", 1, "", "Active region did not converge.");
            }
            vlSelf->__VactIterCount = ((IData)(1U) 
                                       + vlSelf->__VactIterCount);
            vlSelf->__VactContinue = 0U;
            if (Vpe_tb___024root___eval_phase__act(vlSelf)) {
                vlSelf->__VactContinue = 1U;
            }
        }
        if (Vpe_tb___024root___eval_phase__nba(vlSelf)) {
            __VnbaContinue = 1U;
        }
    }
}

#ifdef VL_DEBUG
void Vpe_tb___024root___eval_debug_assertions(Vpe_tb___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe_tb___024root___eval_debug_assertions\n"); );
}
#endif  // VL_DEBUG
