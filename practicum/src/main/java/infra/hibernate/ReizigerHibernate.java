package infra.hibernate;

import domain.IReizigerDao;
import domain.Reiziger;
import jakarta.persistence.EntityManager;
import jakarta.persistence.TypedQuery;

import java.sql.Date;
import java.sql.SQLException;
import java.util.List;

public class ReizigerHibernate implements IReizigerDao {

    private final EntityManager entityManager;

    public ReizigerHibernate(EntityManager entityManager) {
        this.entityManager = entityManager;
    }

    @Override
    public void save(Reiziger reiziger) throws SQLException {
        entityManager.persist(reiziger);
    }

    @Override
    public void update(Reiziger reiziger) throws SQLException {
        entityManager.merge(reiziger);
    }

    @Override
    public void delete(Reiziger reiziger) throws SQLException {
        Reiziger managed = entityManager.contains(reiziger) ? reiziger : entityManager.merge(reiziger);
        entityManager.remove(managed);
    }

    @Override
    public Reiziger findById(int id) throws SQLException {
        return entityManager.find(Reiziger.class, id);
    }

    @Override
    public List<Reiziger> findByGeboorteDatum(Date date) {
        TypedQuery<Reiziger> query = entityManager.createQuery(
                "SELECT r FROM Reiziger r WHERE r.geboortedatum = :datum", Reiziger.class);
        query.setParameter("datum", date);
        return query.getResultList();
    }

    @Override
    public List<Reiziger> findAll() throws SQLException {
        return entityManager.createQuery("SELECT r FROM Reiziger r", Reiziger.class).getResultList();
    }
}
