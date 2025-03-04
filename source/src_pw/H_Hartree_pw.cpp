#include "H_Hartree_pw.h"

#include "../module_base/constants.h"
#include "../module_base/timer.h"
#include "../src_parallel/parallel_reduce.h"

double H_Hartree_pw::hartree_energy = 0.0;

//--------------------------------------------------------------------
// Transform charge density to hartree potential.
//--------------------------------------------------------------------
ModuleBase::matrix H_Hartree_pw::v_hartree(const UnitCell &cell,
                                           ModulePW::PW_Basis* rho_basis,
                                           const int &nspin,
                                           const double *const *const rho)
{
    ModuleBase::TITLE("H_Hartree_pw", "v_hartree");
    ModuleBase::timer::tick("H_Hartree_pw", "v_hartree");

    //  Hartree potential VH(r) from n(r)
    std::vector<std::complex<double>> Porter(rho_basis->nmaxgr);
    const int nspin0 = (nspin == 2) ? 2 : 1;
    for (int is = 0; is < nspin0; is++)
        for (int ir = 0; ir < rho_basis->nrxx; ir++)
            Porter[ir] += std::complex<double>(rho[is][ir], 0.0);
    //=============================
    //  bring rho (aux) to G space
    //=============================
    rho_basis->real2recip(Porter.data(), Porter.data());

    // double charge;
    // if (rho_basis->gstart == 1)
    //     charge = cell.omega * Porter[rho_basis->ig2fftc[0]].real();
    // OUT(GlobalV::ofs_running, "v_h charge", charge);

    //=======================================================
    // calculate hartree potential in G-space (NB: V(G=0)=0 )
    //=======================================================

    double ehart = 0.0;

    std::vector<std::complex<double>> vh_g(rho_basis->npw);
    for (int ig = 0; ig < rho_basis->npw; ig++)
    {
        if (rho_basis->gg[ig] >= 1.0e-8) // LiuXh 20180410
        {
            const double fac = ModuleBase::e2 * ModuleBase::FOUR_PI / (cell.tpiba2 * rho_basis->gg[ig]);

            ehart += (conj(Porter[ig]) * Porter[ig]).real() * fac;
            vh_g[ig] = fac * Porter[ig];
        }
    }

    Parallel_Reduce::reduce_double_pool(ehart);
    ehart *= 0.5 * cell.omega;
    // std::cout << " ehart=" << ehart << std::endl;
    H_Hartree_pw::hartree_energy = ehart;

    //==========================================
    // transform hartree potential to real space
    //==========================================
    rho_basis->recip2real(vh_g.data(), Porter.data());

    //==========================================
    // Add hartree potential to the xc potential
    //==========================================
    ModuleBase::matrix v(nspin, rho_basis->nrxx);
    if (nspin == 4)
    {
        for (int ir = 0; ir < rho_basis->nrxx; ir++)
            v(0, ir) = Porter[ir].real();
    }
    else
    {
        for (int is = 0; is < nspin; is++)
            for (int ir = 0; ir < rho_basis->nrxx; ir++)
                v(is, ir) = Porter[ir].real();
    }

    //-----------------------------------------------------------
    // we need to add this out_pot funciton back
    // in near future, 2021-02-25
    //-----------------------------------------------------------
    //-------------------------------------------
    // output the Hartree potential into a file.
    //-------------------------------------------
    /*
        if(out_pot==-2)
        {
            std::cout << " output VH" << std::endl;
            int is = 0;
            int iter = 0;
            int precision = 3;
            std::string fn = "VH.dat";
            std::stringstream ss;
            ss << GlobalV::global_out_dir << fn;
            ModuleBase::matrix v;
            v.create(1,pwb.nrxx);
            for(int ir=0; ir<pwb.nrxx; ++ir)
            {
                v(0,ir) = Porter[ir].real();
            }
            this->write_potential( is, iter, ss.str(), v, precision, 1 );
        }
    */

    ModuleBase::timer::tick("H_Hartree_pw", "v_hartree");
    return v;
} // end subroutine v_h
