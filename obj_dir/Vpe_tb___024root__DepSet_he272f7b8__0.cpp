// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vpe_tb.h for the primary calling header

#include "Vpe_tb__pch.h"
#include "Vpe_tb__Syms.h"
#include "Vpe_tb___024root.h"

VL_INLINE_OPT VlCoroutine Vpe_tb___024root___eval_initial__TOP__Vtiming__0(Vpe_tb___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe_tb___024root___eval_initial__TOP__Vtiming__0\n"); );
    // Init
    VlWide<6>/*191:0*/ __Vtemp_1;
    // Body
    __Vtemp_1[0U] = 0x2e766364U;
    __Vtemp_1[1U] = 0x64756d70U;
    __Vtemp_1[2U] = 0x2f70655fU;
    __Vtemp_1[3U] = 0x74707574U;
    __Vtemp_1[4U] = 0x6d5f6f75U;
    __Vtemp_1[5U] = 0x7369U;
    vlSymsp->_vm_contextp__->dumpfile(VL_CVT_PACK_STR_NW(6, __Vtemp_1));
    vlSymsp->_traceDumpOpen();
    vlSelf->pe_tb__DOT__clk = 0U;
    vlSelf->pe_tb__DOT__rst_n = 0U;
    vlSelf->pe_tb__DOT__load_en = 0U;
    vlSelf->pe_tb__DOT__in_left = 0U;
    vlSelf->pe_tb__DOT__in_top = 0U;
    co_await vlSelf->__VtrigSched_h0332e823__0.trigger(0U, 
                                                       nullptr, 
                                                       "@(posedge pe_tb.clk)", 
                                                       "tb/unit/ai_acc/pe_tb.sv", 
                                                       25);
    co_await vlSelf->__VdlySched.delay(1ULL, nullptr, 
                                       "tb/unit/ai_acc/pe_tb.sv", 
                                       25);
    co_await vlSelf->__VtrigSched_h0332e823__0.trigger(0U, 
                                                       nullptr, 
                                                       "@(posedge pe_tb.clk)", 
                                                       "tb/unit/ai_acc/pe_tb.sv", 
                                                       26);
    co_await vlSelf->__VdlySched.delay(1ULL, nullptr, 
                                       "tb/unit/ai_acc/pe_tb.sv", 
                                       26);
    vlSelf->pe_tb__DOT__rst_n = 1U;
    co_await vlSelf->__VtrigSched_h0332e823__0.trigger(0U, 
                                                       nullptr, 
                                                       "@(posedge pe_tb.clk)", 
                                                       "tb/unit/ai_acc/pe_tb.sv", 
                                                       29);
    co_await vlSelf->__VdlySched.delay(1ULL, nullptr, 
                                       "tb/unit/ai_acc/pe_tb.sv", 
                                       29);
    vlSelf->pe_tb__DOT__load_en = 1U;
    vlSelf->pe_tb__DOT__in_left = 3U;
    co_await vlSelf->__VtrigSched_h0332e823__0.trigger(0U, 
                                                       nullptr, 
                                                       "@(posedge pe_tb.clk)", 
                                                       "tb/unit/ai_acc/pe_tb.sv", 
                                                       33);
    co_await vlSelf->__VdlySched.delay(1ULL, nullptr, 
                                       "tb/unit/ai_acc/pe_tb.sv", 
                                       33);
    vlSelf->pe_tb__DOT__load_en = 0U;
    vlSelf->pe_tb__DOT__in_left = 2U;
    co_await vlSelf->__VtrigSched_h0332e823__0.trigger(0U, 
                                                       nullptr, 
                                                       "@(posedge pe_tb.clk)", 
                                                       "tb/unit/ai_acc/pe_tb.sv", 
                                                       37);
    co_await vlSelf->__VdlySched.delay(1ULL, nullptr, 
                                       "tb/unit/ai_acc/pe_tb.sv", 
                                       37);
    vlSelf->pe_tb__DOT__in_left = 4U;
    vlSelf->pe_tb__DOT__in_top = 6U;
    co_await vlSelf->__VtrigSched_h0332e823__0.trigger(0U, 
                                                       nullptr, 
                                                       "@(posedge pe_tb.clk)", 
                                                       "tb/unit/ai_acc/pe_tb.sv", 
                                                       41);
    co_await vlSelf->__VdlySched.delay(1ULL, nullptr, 
                                       "tb/unit/ai_acc/pe_tb.sv", 
                                       41);
    vlSelf->pe_tb__DOT__in_left = 0xffU;
    vlSelf->pe_tb__DOT__in_top = 0U;
    co_await vlSelf->__VtrigSched_h0332e823__0.trigger(0U, 
                                                       nullptr, 
                                                       "@(posedge pe_tb.clk)", 
                                                       "tb/unit/ai_acc/pe_tb.sv", 
                                                       45);
    co_await vlSelf->__VdlySched.delay(1ULL, nullptr, 
                                       "tb/unit/ai_acc/pe_tb.sv", 
                                       45);
    co_await vlSelf->__VtrigSched_h0332e823__0.trigger(0U, 
                                                       nullptr, 
                                                       "@(posedge pe_tb.clk)", 
                                                       "tb/unit/ai_acc/pe_tb.sv", 
                                                       46);
    co_await vlSelf->__VdlySched.delay(1ULL, nullptr, 
                                       "tb/unit/ai_acc/pe_tb.sv", 
                                       46);
    VL_FINISH_MT("tb/unit/ai_acc/pe_tb.sv", 47, "");
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vpe_tb___024root___dump_triggers__act(Vpe_tb___024root* vlSelf);
#endif  // VL_DEBUG

void Vpe_tb___024root___eval_triggers__act(Vpe_tb___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe_tb___024root___eval_triggers__act\n"); );
    // Body
    vlSelf->__VactTriggered.set(0U, (((IData)(vlSelf->pe_tb__DOT__clk) 
                                      & (~ (IData)(vlSelf->__Vtrigprevexpr___TOP__pe_tb__DOT__clk__0))) 
                                     | ((~ (IData)(vlSelf->pe_tb__DOT__rst_n)) 
                                        & (IData)(vlSelf->__Vtrigprevexpr___TOP__pe_tb__DOT__rst_n__0))));
    vlSelf->__VactTriggered.set(1U, vlSelf->__VdlySched.awaitingCurrentTime());
    vlSelf->__VactTriggered.set(2U, ((IData)(vlSelf->pe_tb__DOT__clk) 
                                     & (~ (IData)(vlSelf->__Vtrigprevexpr___TOP__pe_tb__DOT__clk__0))));
    vlSelf->__Vtrigprevexpr___TOP__pe_tb__DOT__clk__0 
        = vlSelf->pe_tb__DOT__clk;
    vlSelf->__Vtrigprevexpr___TOP__pe_tb__DOT__rst_n__0 
        = vlSelf->pe_tb__DOT__rst_n;
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vpe_tb___024root___dump_triggers__act(vlSelf);
    }
#endif
}
