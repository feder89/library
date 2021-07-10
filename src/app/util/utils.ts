import { Book } from '../interfaces/book';
import { Publisher } from '../interfaces/publisher';
import { School } from '../interfaces/school';
import { Class } from '../interfaces/class';
import { Student } from '../interfaces/student';
import * as moment from 'moment';
import { Wholesaler } from '../interfaces/wholesaler';

export class Utils {

  public mapperBookToDbObject(book: Book): any {
    const mapped: any = {
      titolo: book.titolo,
      prezzo: book.prezzo,
      codice_isbn: book.codice_isbn,
      casa_editrice: book.casa_editrice,
      tomi: book.tomi,
      materia: book.materia
    };
    if (book.id !== null && book.id !== -1) {
      mapped.id = book.id;
    }

    return mapped;
  }

  public mapperClassToDbObject(c: Class): any {
    const mapped: any = {
      nome: c.nome,
      scuola: c.scuola,
    };
    if (c.id !== null) {
      mapped.id = c.id;
    }

    return mapped;
  }

  public mapperPublisherToBeInserted(p: Publisher): any {
    const ret: any = {
      nome: p.nome,
      cap: p.cap,
      iva: p.iva,
      indirizzo: p.indirizzo,
      citta: p.citta,
      provincia: p.provincia,
      mail: p.mail,
      telefono: p.telefono
    };
    if (p.id !== null) {
      ret.id = p.id;
    }
    return ret;
  }

  public mapperSchoolToBeInserted(s: School): any {
    return {
      nome: s.nome,
      tipologia: s.tipologia
    };
  }

  public mapperStudentToDbObject(s: Student): any {
    const student: any = {
      nome: s.nome,
      cognome: s.cognome,
      classe: s.classe,
      residenza: s.residenza,
      mail: s.mail,
      telefono: s.telefono,
    };
    if (s.id !== null) {
      student.id = s.id;
    }

    return student;
  }

  public formatDatetime(date: string): string {
    return moment(date).local().format('DD-MM-YYYY' + ' ' + moment.HTML5_FMT.TIME_SECONDS);
  }

  public mapperBookingToDbObject(obj: any, idBooking: number, idStudent: number): any {
    const booking: any = {
      studente: idStudent,
      prenotazione: idBooking,
      libro: obj.libri.id,
      foderatura: obj.foderatura,
      cedola: obj.cedola,
      stato: obj.stato
    };

    if (obj.id != null && obj.id !== 0) {
      booking.id = obj.id;
    }

    return booking;
  }

  public mappingBookingToDbObject(bkng: any): any {
    const booking: any = {
      data: bkng.data,
      caparra: bkng.caparra,
      note: bkng.note
    };

    if (bkng.id != null) {
      booking.id = bkng.id;
    }
    return booking;
  }

  public mapperWholesalerToBeInserted(w: Wholesaler): any {
    const ret: any = {
      nome: w.nome,
      iva: w.iva,
      indirizzo: w.indirizzo,
      citta: w.citta,
      provincia: w.provincia,
      mail: w.mail,
      telefono: w.telefono,
      cap: w.cap
    };
    if (w.id !== null) {
      ret.id = w.id;
    }

    return ret;
  }
}
