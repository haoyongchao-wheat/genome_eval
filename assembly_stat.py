import argparse
from Bio import SeqIO
import numpy as np

def calculate_nx(sorted_lengths, total_length, percentage):
    """Calculate Nx and Lx values for a given percentage."""
    target = total_length * (percentage / 100)
    cumulative = 0
    for i, length in enumerate(sorted_lengths):
        cumulative += length
        if cumulative >= target:
            return length, i + 1
    return 0, 0

def main(fasta_file):
    """Calculate and print assembly statistics from a FASTA file."""
    # Parse FASTA file
    contigs = list(SeqIO.parse(fasta_file, "fasta"))
    lengths = [len(contig.seq) for contig in contigs]
    
    # Basic metrics
    total_contigs = len(lengths)
    total_length = sum(lengths)
    sorted_lengths = sorted(lengths, reverse=True)

    # N50, L50, N90, L90
    n50, l50 = calculate_nx(sorted_lengths, total_length, 50)
    n90, l90 = calculate_nx(sorted_lengths, total_length, 90)

    # Longest and average contig length
    longest_contig = max(lengths) if lengths else 0
    average_length = total_length / total_contigs if total_contigs > 0 else 0

    # Contigs above length thresholds
    contigs_over_10k = sum(1 for length in lengths if length > 10000)
    contigs_over_100k = sum(1 for length in lengths if length > 100000)

    # Initialize nucleotide counters
    total_gc = 0
    total_a = total_t = total_c = total_g = total_n = 0
    
    for contig in contigs:
        seq = contig.seq.upper()
        total_a += seq.count('A')
        total_t += seq.count('T')
        total_c += seq.count('C')
        total_g += seq.count('G')
        total_n += len(seq) - (seq.count('A') + seq.count('T') + seq.count('C') + seq.count('G'))
    
    total_bases = total_a + total_t + total_c + total_g + total_n
    gc_content = (total_c + total_g) / total_bases * 100 if total_bases > 0 else 0
    
    # Calculate nucleotide percentages
    a_content = total_a / total_bases * 100 if total_bases > 0 else 0
    t_content = total_t / total_bases * 100 if total_bases > 0 else 0
    c_content = total_c / total_bases * 100 if total_bases > 0 else 0
    g_content = total_g / total_bases * 100 if total_bases > 0 else 0
    n_content = total_n / total_bases * 100 if total_bases > 0 else 0

    # Output results
    print(f"总 contig 数量: {total_contigs}")
    print(f"总长度: {total_length} bp")
    print(f"N50: {n50} bp")
    print(f"L50: {l50}")
    print(f"N90: {n90} bp")
    print(f"L90: {l90}")
    print(f"最长 contig: {longest_contig} bp")
    print(f"平均 contig 长度: {average_length:.2f} bp")
    print(f"大于 10kbp 的 contig 数量: {contigs_over_10k}")
    print(f"大于 100kbp 的 contig 数量: {contigs_over_100k}")
    print(f"GC 含量: {gc_content:.2f}%")
    print("\n碱基组成统计:")
    print(f"A 含量: {a_content:.2f}%")
    print(f"T 含量: {t_content:.2f}%")
    print(f"C 含量: {c_content:.2f}%")
    print(f"G 含量: {g_content:.2f}%")
    print(f"N 或其他非标准碱基含量: {n_content:.2f}%")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="统计 contig 级别基因组草图的各项指标")
    parser.add_argument("fasta_file", help="包含基因组组装的 FASTA 文件路径")
    args = parser.parse_args()
    main(args.fasta_file)
