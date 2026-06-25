package infra.dao;

import domain.*;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ReizigerDaoPsql implements IReizigerDao {

    private final Connection connection;
    private IOvChipkaartDao ovChipkaartDao;
    private IAdresDao adresDao;

    public ReizigerDaoPsql(Connection connection) {
        this.connection = connection;
    }

    @Override
    public void save(Reiziger reiziger) throws SQLException {
        String sql = "INSERT INTO reiziger (reiziger_id, voorletters, tussenvoegsel, achternaam, geboortedatum) "
                + "VALUES (?, ?, ?, ?, ?)";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setInt(1, reiziger.getReizigerId());
            ps.setString(2, reiziger.getVoorletters());
            ps.setString(3, reiziger.getTussenvoegsel());
            ps.setString(4, reiziger.getAchternaam());
            ps.setDate(5, reiziger.getGeboortedatum());
            ps.executeUpdate();
        }
    }

    @Override
    public void update(Reiziger reiziger) throws SQLException {
        String sql = "UPDATE reiziger SET voorletters = ?, tussenvoegsel = ?, achternaam = ?, geboortedatum = ? "
                + "WHERE reiziger_id = ?";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setString(1, reiziger.getVoorletters());
            ps.setString(2, reiziger.getTussenvoegsel());
            ps.setString(3, reiziger.getAchternaam());
            ps.setDate(4, reiziger.getGeboortedatum());
            ps.setInt(5, reiziger.getReizigerId());
            ps.executeUpdate();
        }
    }

    @Override
    public void delete(Reiziger reiziger) throws SQLException {
        String sql = "DELETE FROM reiziger WHERE reiziger_id = ?";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setInt(1, reiziger.getReizigerId());
            ps.executeUpdate();
        }
    }

    @Override
    public Reiziger findById(int id) throws SQLException {
        String sql = "SELECT * FROM reiziger WHERE reiziger_id = ?";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
                return null;
            }
        }
    }

    @Override
    public List<Reiziger> findByGeboorteDatum(Date date) throws SQLException {
        List<Reiziger> reizigers = new ArrayList<>();
        String sql = "SELECT * FROM reiziger WHERE geboortedatum = ?";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setDate(1, date);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    reizigers.add(mapRow(rs));
                }
            }
        }
        return reizigers;
    }

    @Override
    public List<Reiziger> findAll() throws SQLException {
        List<Reiziger> reizigers = new ArrayList<>();
        String sql = "SELECT * FROM reiziger";
        try (PreparedStatement ps = connection.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                reizigers.add(mapRow(rs));
            }
        }
        return reizigers;
    }

    private Reiziger mapRow(ResultSet rs) throws SQLException {
        Reiziger reiziger = new Reiziger();
        reiziger.setReizigerId(rs.getInt("reiziger_id"));
        reiziger.setVoorletters(rs.getString("voorletters"));
        reiziger.setTussenvoegsel(rs.getString("tussenvoegsel"));
        reiziger.setAchternaam(rs.getString("achternaam"));
        reiziger.setGeboortedatum(rs.getDate("geboortedatum"));
        return reiziger;
    }

    public void setAdresDao(IAdresDao adresDaoPsql) {
        this.adresDao = adresDaoPsql;
    }

    public void setOvChipkaartDao(IOvChipkaartDao ovChipkaartDaoPsql) {
        this.ovChipkaartDao = ovChipkaartDaoPsql;
    }
}
