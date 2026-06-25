package domain;

import jakarta.persistence.*;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.sql.Date;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "ov_chipkaart")
public class OvChipkaart {

    @Id
    @Column(name = "kaart_nummer")
    private int kaartNummer;

    @Column(name = "geldig_tot")
    private Date geldigTot;

    @Column(name = "klasse")
    private BigInteger klasse;

    @Column(name = "saldo")
    private BigDecimal saldo;

    // Wordt in P4 een @ManyToOne; voorlopig transient.
    @Transient
    private Reiziger reiziger;

    // Wordt in P5 een @ManyToMany; voorlopig transient.
    @Transient
    private List<Product> producten = new ArrayList<>();

    public OvChipkaart() {}

    public int getKaartNummer() {
        return kaartNummer;
    }

    public void setKaartNummer(int kaartNummer) {
        this.kaartNummer = kaartNummer;
    }

    public Date getGeldigTot() {
        return geldigTot;
    }

    public void setGeldigTot(Date geldigTot) {
        this.geldigTot = geldigTot;
    }

    public BigInteger getKlasse() {
        return klasse;
    }

    public void setKlasse(BigInteger klasse) {
        this.klasse = klasse;
    }

    public BigDecimal getSaldo() {
        return saldo;
    }

    public void setSaldo(BigDecimal saldo) {
        this.saldo = saldo;
    }

    public Reiziger getReiziger() {
        return reiziger;
    }

    public void setReiziger(Reiziger reiziger) {
        this.reiziger = reiziger;
    }

    public List<Product> getProducten() {
        return producten;
    }

    public void setProducten(List<Product> producten) {
        this.producten = producten;
    }

    @Override
    public String toString() {
        return "OV-chipkaart #" + kaartNummer + " (klasse " + klasse + ", saldo " + saldo
                + ", geldig tot " + geldigTot + ")";
    }
}
