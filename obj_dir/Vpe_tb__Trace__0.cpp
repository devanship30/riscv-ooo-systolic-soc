// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Tracing implementation internals
#include "verilated_vcd_c.h"
#include "Vpe_tb__Syms.h"


void Vpe_tb___024root__trace_chg_0_sub_0(Vpe_tb___024root* vlSelf, VerilatedVcd::Buffer* bufp);

void Vpe_tb___024root__trace_chg_0(void* voidSelf, VerilatedVcd::Buffer* bufp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe_tb___024root__trace_chg_0\n"); );
    // Init
    Vpe_tb___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vpe_tb___024root*>(voidSelf);
    Vpe_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    if (VL_UNLIKELY(!vlSymsp->__Vm_activity)) return;
    // Body
    Vpe_tb___024root__trace_chg_0_sub_0((&vlSymsp->TOP), bufp);
}

void Vpe_tb___024root__trace_chg_0_sub_0(Vpe_tb___024root* vlSelf, VerilatedVcd::Buffer* bufp) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe_tb___024root__trace_chg_0_sub_0\n"); );
    // Init
    uint32_t* const oldp VL_ATTR_UNUSED = bufp->oldp(vlSymsp->__Vm_baseCode + 1);
    // Body
    if (VL_UNLIKELY(vlSelf->__Vm_traceActivity[1U])) {
        bufp->chgCData(oldp+0,(vlSelf->pe_tb__DOT__out_right),8);
        bufp->chgIData(oldp+1,(vlSelf->pe_tb__DOT__out_bottom),32);
        bufp->chgCData(oldp+2,(vlSelf->pe_tb__DOT__uut__DOT__weight_reg),8);
    }
    bufp->chgBit(oldp+3,(vlSelf->pe_tb__DOT__clk));
    bufp->chgBit(oldp+4,(vlSelf->pe_tb__DOT__rst_n));
    bufp->chgBit(oldp+5,(vlSelf->pe_tb__DOT__load_en));
    bufp->chgCData(oldp+6,(vlSelf->pe_tb__DOT__in_left),8);
    bufp->chgIData(oldp+7,(vlSelf->pe_tb__DOT__in_top),32);
}

void Vpe_tb___024root__trace_cleanup(void* voidSelf, VerilatedVcd* /*unused*/) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe_tb___024root__trace_cleanup\n"); );
    // Init
    Vpe_tb___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vpe_tb___024root*>(voidSelf);
    Vpe_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    // Body
    vlSymsp->__Vm_activity = false;
    vlSymsp->TOP.__Vm_traceActivity[0U] = 0U;
    vlSymsp->TOP.__Vm_traceActivity[1U] = 0U;
}
