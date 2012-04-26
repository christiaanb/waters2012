\documentclass[conference,a4paper,10pt]{IEEEtran}
\IEEEoverridecommandlockouts

\usepackage{ifthen}
%include lineno.fmt
\input{preamble.dem}
%include waters2012.fmt

\begin{document}

\title{PANACEA - Functional System Design Space Exploration}

\author{\IEEEauthorblockN{Christiaan Baaij\thanks{Supported through the S(o)OS project, sponsored by the European Commission under FP7-ICT-2009.8.1, Grant Agreement No. 248465}, Jan Kuper}
\IEEEauthorblockA{Computer Architecture for Embedded Systems\\
Department of EEMCS, University of Twente\\
Postbus 217, 7500AE Enschede, The Netherlands\\
Email: \url{c.p.r.baaij@@utwente.nl}}
}

\maketitle

\begin{abstract}
\boldmath
To offer the panacea for complete system design space exploration, from hardware, over the OS, to applications.
To put an end to crappy 6-core, 2-router NoC/SoC examples --- where a fully-connected point-to-point architecture would work better --- found in accepted papers at `respected' conferences.
\end{abstract}

\section{Introduction}
Simulation is commonly used tool in the exploration of many design ascpects of a system: ranging from feasabiltiy aspects to gathering performance information.
Simulation in the domain of computer science is however most oftenly used to gather the performance characteristics of the simulated system.
These simulations often make a trade-off between the accurarcy of the results, and the speed of simulator.
In general however, most simulation frameworks require a high degree of detail in the description of the system.

\section{}

\section{Related Work}

\section{Conclusions}

\section{Future Work}

\bibliographystyle{IEEEtran}
\bibliography{waters2012}

\end{document}
