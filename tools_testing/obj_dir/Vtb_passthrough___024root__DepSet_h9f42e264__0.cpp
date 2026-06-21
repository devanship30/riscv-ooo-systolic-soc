// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_passthrough.h for the primary calling header

#include "Vtb_passthrough__pch.h"
#include "Vtb_passthrough__Syms.h"
#include "Vtb_passthrough___024root.h"

VL_INLINE_OPT VlCoroutine Vtb_passthrough___024root___eval_initial__TOP__Vtiming__0(Vtb_passthrough___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_passthrough__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_passthrough___024root___eval_initial__TOP__Vtiming__0\n"); );
    // Body
    vlSymsp->_vm_contextp__->dumpfile(std::string{"dump.vcd"});
    vlSymsp->_traceDumpOpen();
    vlSelf->tb_passthrough__DOT__rst_n = 0U;
    vlSelf->tb_passthrough__DOT__clk = 0U;
    vlSelf->tb_passthrough__DOT__i_8bit = 0U;
    co_await vlSelf->__VdlySched.delay(0xaULL, nullptr, 
                                       "tb_passthrough.sv", 
                                       20);
    vlSelf->tb_passthrough__DOT__rst_n = 1U;
    co_await vlSelf->__VdlySched.delay(0x14ULL, nullptr, 
                                       "tb_passthrough.sv", 
                                       21);
    vlSelf->tb_passthrough__DOT__i_8bit = 4U;
    co_await vlSelf->__VdlySched.delay(0x28ULL, nullptr, 
                                       "tb_passthrough.sv", 
                                       22);
    vlSelf->tb_passthrough__DOT__i_8bit = 0U;
    co_await vlSelf->__VdlySched.delay(0x14ULL, nullptr, 
                                       "tb_passthrough.sv", 
                                       23);
    vlSelf->tb_passthrough__DOT__rst_n = 0U;
    co_await vlSelf->__VdlySched.delay(0x28ULL, nullptr, 
                                       "tb_passthrough.sv", 
                                       24);
    vlSelf->tb_passthrough__DOT__rst_n = 1U;
    co_await vlSelf->__VdlySched.delay(0x14ULL, nullptr, 
                                       "tb_passthrough.sv", 
                                       25);
    vlSelf->tb_passthrough__DOT__i_8bit = 1U;
    co_await vlSelf->__VdlySched.delay(0x14ULL, nullptr, 
                                       "tb_passthrough.sv", 
                                       26);
    VL_FINISH_MT("tb_passthrough.sv", 26, "");
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_passthrough___024root___dump_triggers__act(Vtb_passthrough___024root* vlSelf);
#endif  // VL_DEBUG

void Vtb_passthrough___024root___eval_triggers__act(Vtb_passthrough___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_passthrough__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_passthrough___024root___eval_triggers__act\n"); );
    // Body
    vlSelf->__VactTriggered.set(0U, (((IData)(vlSelf->tb_passthrough__DOT__clk) 
                                      & (~ (IData)(vlSelf->__Vtrigprevexpr___TOP__tb_passthrough__DOT__clk__0))) 
                                     | ((~ (IData)(vlSelf->tb_passthrough__DOT__rst_n)) 
                                        & (IData)(vlSelf->__Vtrigprevexpr___TOP__tb_passthrough__DOT__rst_n__0))));
    vlSelf->__VactTriggered.set(1U, vlSelf->__VdlySched.awaitingCurrentTime());
    vlSelf->__Vtrigprevexpr___TOP__tb_passthrough__DOT__clk__0 
        = vlSelf->tb_passthrough__DOT__clk;
    vlSelf->__Vtrigprevexpr___TOP__tb_passthrough__DOT__rst_n__0 
        = vlSelf->tb_passthrough__DOT__rst_n;
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vtb_passthrough___024root___dump_triggers__act(vlSelf);
    }
#endif
}
