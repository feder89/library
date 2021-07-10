import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { BooksListByStudentComponent } from './books-list-by-student.component';

describe('BooksListByStudentComponent', () => {
  let component: BooksListByStudentComponent;
  let fixture: ComponentFixture<BooksListByStudentComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ BooksListByStudentComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(BooksListByStudentComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
